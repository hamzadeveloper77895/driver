# Backend Architecture & Technical Design (08_BACKEND_DESIGN.md)

This document details the architecture, engineering principles, concurrency patterns, and technical subsystems of the FastAPI backend in `/backend`.

---

## 1. System Architecture Overview

```
                                      +-------------------------+
                                      |   Flutter Mobile App    |
                                      |   (Customer / Driver)   |
                                      +------------+------------+
                                                   | HTTP / REST & WSS
                                                   v
+---------------------------------------------------------------------------------------------------+
| FastAPI Application Server                                                                        |
|                                                                                                   |
|  +--------------------+   +---------------------+   +---------------------+   +----------------+  |
|  |   Auth Router      |   |   Bookings Router   |   |   Driver Router     |   | Wallet Router  |  |
|  |   JWT & OTP        |   |   State Machine     |   |   Telemetry & Duty  |   | Ledger & Promo |  |
|  +---------+----------+   +----------+----------+   +----------+----------+   +-------+--------+  |
|            |                         |                         |                      |           |
|            +-------------------------+----+--------------------+----------------------+           |
|                                           |                                                       |
|                                           v                                                       |
|                     +---------------------------------------------+                               |
|                     |        Core Services & Domain Logic         |                               |
|                     |  - DispatchEngine (Redis GEO)               |                               |
|                     |  - PricingService (Formulas & Surcharges)   |                               |
|                     |  - WebSocketConnectionManager (Pub/Sub)     |                               |
|                     |  - BookingStateMachine (Invariants & Tests) |                               |
|                     +---------------------+-----------------------+                               |
+-------------------------------------------|-------------------------------------------------------+
                                            |
                         +------------------+------------------+
                         |                                     |
                         v                                     v
         +-------------------------------+     +-------------------------------+
         |    PostgreSQL 16 Database     |     |     Redis 7 In-Memory Store   |
         |    - SQLAlchemy 2 Async       |     |    - GEO Spatial Indexing     |
         |    - Relational Entities      |     |    - Pub/Sub Trip Channels    |
         |    - Immutable Ledger Logs    |     |    - Distributed Locks (Redlock)
         +-------------------------------+     +-------------------------------+
```

---

## 2. Authentication & Authorization

### 2.1 OTP Verification Flow
- **Request OTP**: Customer or driver enters phone number. A 6-digit random code is generated and stored in Redis with key `otp:<phone>` and TTL of 300 seconds (5 minutes). In development/test mode, OTP defaults to `123456`.
- **Verify OTP**: Code is verified and consumed (preventing replay attacks). If phone is not in `users`, a new record is created with `is_new_user = true`.
- **JWT Issuance**:
  - `access_token`: Valid for 15 minutes, signed with `HS256`. Payload contains: `sub` (User UUID), `phone`, `role` (`CUSTOMER`, `DRIVER`, `ADMIN`), and `exp`.
  - `refresh_token`: Stored in Redis with 30-day TTL (`refresh:<user_id>`). Used to issue fresh access tokens via `POST /api/v1/auth/refresh-token`.

---

## 3. Realtime WebSocket & Redis Pub/Sub Subsystem

### 3.1 Channel Architecture
To allow horizontal scaling across multiple FastAPI instances, state events and telemetry are routed through Redis Pub/Sub:
- **Trip Status & Telemetry Channel**: `channel:trip:<booking_id>`
- **Driver Dispatch Notification Channel**: `channel:driver:dispatch:<driver_id>`

### 3.2 Snapshot-On-Connect Pattern
When a client connects to `WSS /ws/trips/{booking_id}`, the server immediately sends a full hydration snapshot frame before listening to the pub/sub queue:
```json
{
  "event": "HYDRATION_SNAPSHOT",
  "data": {
    "booking_id": "8f3b...",
    "status": "ON_WAY",
    "driver": {
      "id": "1d2a...",
      "full_name": "Rajesh Kumar",
      "phone": "+919811122233",
      "current_lat": 12.9720,
      "current_lng": 77.5950,
      "bearing": 180.0
    },
    "start_otp": "5824"
  }
}
```

### 3.3 Event Vocabulary
- `DRIVER_ASSIGNED`: Sent when a driver claims a booking.
- `DRIVER_LOCATION_UPDATE`: Live latitude/longitude/bearing/speed tick.
- `DRIVER_ARRIVED`: Driver within 100m of pickup point.
- `TRIP_STARTED`: OTP verified; meter started.
- `TRIP_COMPLETED`: Trip concluded; final fare calculation delivered.
- `BOOKING_CANCELLED`: Trip cancelled with reason.

---

## 4. Redis Geospatial Dispatch Engine

### 4.1 Driver Positioning
When drivers are online, their location is recorded in Redis using `GEOADD`:
```bash
GEOADD drivers:available 77.594566 12.971598 "driver_uuid_123"
```

### 4.2 Proximity Query & Radius Escalation
```python
# Radius query with sorted proximity
nearby_drivers = await redis.geosearch(
    name="drivers:available",
    longitude=pickup_lng,
    latitude=pickup_lat,
    radius=radius_km,
    unit="km",
    sort="ASC",
    count=10,
    withdist=True
)
```
- **Radius Schedule**: 3.0 km (0-20s) -> 6.0 km (20-40s) -> 10.0 km (40-60s).

### 4.3 Atomic Offer Claiming
When a driver accepts an offer, the API uses a distributed lock:
```python
acquired = await redis.set(f"lock:booking:{booking_id}", driver_id, nx=True, ex=10)
if not acquired:
    raise HTTPException(status_code=409, detail="Offer already claimed")
```

---

## 5. Pricing Engine Specifications

### 5.1 Pricing Matrix
- **Hourly City Package**:
  - Minimum 2 hours: $25.00 base fare.
  - Extra minutes: $0.20 per minute.
- **Night Surcharge**:
  - $5.00 flat surcharge applied if trip spans 22:00 to 06:00.
- **Taxes**:
  - 18% standard GST / VAT applied to subtotal.
- **Cancellation Policy**:
  - Free cancellation within 5 minutes of driver assignment.
  - $5.00 flat fee if cancelled after 5 minutes or after driver arrival.

---

## 6. Automated Driver Simulator

The backend includes a built-in simulation engine (`app/simulator.py`) for automated testing and demo purposes:
- Spawns virtual drivers around target coordinates.
- Listens on Redis for new dispatch offers matching transmission capabilities.
- Simulates realistic driver travel velocities (30-45 km/h) along path coordinates.
- Executes trip progression: Arrive -> Submit OTP -> Drive -> Complete.
- Allows fully autonomous end-to-end booking verification in continuous integration.
