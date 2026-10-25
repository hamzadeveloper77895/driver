# Feature Workflows Specification (05_FEATURES.md)

This document provides end-to-end procedural workflows, actor interactions, business logic, edge case handling, and integration points for each major platform capability.

---

## 1. Feature: On-Demand & Scheduled Chauffeur Booking

### 1.1 Objective
Enables customers to request a professional chauffeur to drive the customer's own vehicle either immediately or scheduled for a specific departure time.

### 1.2 Workflow Steps
1. **Origin & Destination Selection**:
   - Customer confirms pickup address (defaults to current GPS location with reverse geocoding).
   - Optional drop-off address (mandatory for Round Trip / Outstation, optional for flexible hourly city drives).
2. **Trip Configuration**:
   - Service Type: `HOURLY_LOCAL` (2h, 4h, 8h packages) or `OUTSTATION_ROUND_TRIP`.
   - Departure Time: `NOW` (immediate dispatch) or `SCHEDULED` (date & time up to 7 days in advance).
   - Vehicle Selection: customer chooses vehicle from their Garage. **Crucial**: the vehicle's transmission type (`MANUAL` vs `AUTOMATIC`) is attached as a hard constraint for driver dispatch.
3. **Fare Quote & Confirmation**:
   - Backend computes guaranteed fare estimate including base package duration, night surcharges, taxes, and promo code deduction.
   - Customer selects payment preference (Wallet, Card, Cash).
   - Customer taps "Confirm Booking", creating a booking in `PENDING` state and triggering the Dispatch Engine.

### 1.3 Edge Cases
- **No Vehicle in Garage**: Directs customer to quick-add car modal (takes < 20 seconds).
- **Insufficient Wallet Balance**: Prompts user to top up or switch payment method to Cash/Card.
- **Scheduled Booking Conflict**: Rejects bookings scheduled within less than 45 minutes of current time (must use "Now").

---

## 2. Feature: Geospatial Driver Dispatch Engine

### 2.1 Objective
Matches and dispatches booking requests to the closest available, qualified chauffeur with an automated fallback escalation.

### 2.2 Algorithm & Step Progression
1. **Driver Candidate Pool Discovery**:
   - Queries Redis `GEOSEARCH` around pickup coordinates with an initial radius of `3.0 km`.
   - Filters candidate driver IDs against online status (`status == ONLINE`) and transmission skill set:
     - If customer vehicle is `AUTOMATIC`, driver must have `can_drive_automatic == true`.
     - If customer vehicle is `MANUAL`, driver must have `can_drive_manual == true`.
2. **Offer Dispatch**:
   - Sorts candidates by proximity (shortest driving ETA).
   - Selects top candidate (or top 3 in wave 1) and publishes an offer notification over Redis pub/sub to driver WebSocket channel `driver:dispatch:<driver_id>`.
   - Starts a 30-second countdown timer.
3. **Driver Acceptance / Decline**:
   - If Driver **Accepts**:
     - Locks booking atomically with Redis distributed lock (`SET booking:lock:<id> NX EX 5`).
     - Transitions booking status to `DRIVER_ASSIGNED`.
     - Publishes acceptance to customer trip channel `trip:status:<booking_id>`.
   - If Driver **Declines** or **Times Out**:
     - Blacklists declined driver for this booking.
     - Automatically expands search radius to `6.0 km` and alerts next candidate.
     - If no match after `60 seconds`, transitions to `NO_DRIVERS_AVAILABLE` and notifies customer with retry options.

---

## 3. Feature: Secure Trip Verification via Start-Trip OTP

### 3.1 Objective
Guarantees that the chauffeur meets the right customer and vehicle before starting trip metering, eliminating fraudulent trip activations.

### 3.2 Workflow Steps
1. Upon booking transition to `DRIVER_ASSIGNED`, backend generates a cryptographically random 4-digit PIN (e.g., `5824`) and stores it securely in the booking record.
2. The PIN is displayed prominently on the Customer's live tracking screen ("Share this OTP with your driver upon arrival").
3. The driver arrives at pickup and taps "Arrived at Pickup Location" (transitions booking to `ARRIVED`).
4. Driver meets customer, verifies customer car license plate, and asks for the 4-digit OTP.
5. Driver enters the OTP in the Driver App dialog and submits to `POST /api/v1/driver/trips/{id}/start`.
6. Backend validates OTP:
   - If Match: transitions booking to `IN_PROGRESS`, records `trip_start_time = NOW()`, and notifies customer via WebSocket.
   - If Mismatch: rejects request with HTTP 400 (`INVALID_OTP`). Locks account for 10 minutes after 3 consecutive failures.

---

## 4. Feature: Live Real-Time Telemetry & Tracking

### 4.1 Objective
Provides continuous, battery-optimized live tracking of driver vehicle position on the customer map with low latency (< 1 second).

### 4.2 Telemetry Protocol
1. **Driver Ingestion**:
   - When on active duty, driver app emits telemetry packets every 3 seconds to `POST /api/v1/driver/telemetry` or WebSocket:
     ```json
     {
       "latitude": 12.971598,
       "longitude": 77.594566,
       "bearing": 182.4,
       "speed": 28.5,
       "timestamp": "2026-10-24T18:15:00Z"
     }
     ```
2. **Redis Ingestion & Geospatial Index**:
   - Updates driver location in Redis GEO index `drivers:locations` via `GEOADD`.
   - Updates driver last heartbeat key with 60-second TTL.
3. **Customer Fan-Out**:
   - If driver is assigned to an active trip, publishes coordinates to Redis pub/sub channel `trip:telemetry:<booking_id>`.
   - The FastAPI WebSocket gateway delivers message to customer's connected socket:
     ```json
     {
       "event": "DRIVER_LOCATION_UPDATE",
       "data": {
         "lat": 12.971598,
         "lng": 77.594566,
         "bearing": 182.4,
         "eta_minutes": 6
       }
     }
     ```
4. **Client-Side Map Interpolation**:
   - Flutter app smoothly animates driver vehicle marker along bearing angle using spherical tween interpolation.

---

## 5. Feature: In-App Driver Chat & Masked Voice Calls

### 5.1 Objective
Seamless communication between customer and assigned chauffeur without exposing private personal phone numbers.

### 5.2 Workflow Steps
1. Chat session created upon driver assignment, identified by `booking_id`.
2. Customer or driver sends text message:
   - Message saved in database `chat_messages` table.
   - Real-time event `NEW_CHAT_MESSAGE` broadcasted to recipient's active WebSocket connection.
   - If recipient is backgrounded, triggers push notification via FCM.
3. Voice Calling:
   - Tapping phone icon initiates masked VoIP / bridge phone call.
4. Chat session automatically closed upon trip completion.

---

## 6. Feature: Safety & Emergency SOS Broadcast

### 6.1 Objective
Immediate safety escalation in case of medical emergency, accident, or threat during an active ride.

### 6.2 Workflow Steps
1. Customer triggers "Emergency SOS" by holding button for 3 seconds.
2. System immediately:
   - Marks booking record with `emergency_sos_triggered = true` and logs timestamp and exact GPS coordinates.
   - Pushes high-priority alert to Admin Safety Console.
   - Dispatches automated SMS with live GPS tracking link to all saved emergency contacts.
   - Presents one-touch button to call national emergency services (911 / 112).

---

## 7. Feature: Dynamic Fare Settlement & Multi-Channel Payments

### 7.1 Objective
Accurate metering of elapsed ride duration, transparent bill generation, and automated settlement.

### 7.2 Fare Calculation Formula
$$\text{Total Fare} = \text{Base Fare} + \max(0, \text{Actual Minutes} - \text{Base Minutes}) \times \text{Extra Rate} + \text{Night Surcharge} + \text{Toll/Parking} - \text{Discount} + \text{GST (18\%)}$$

### 7.3 Settlement Options
- **In-App Digital Wallet**: Automatically debited on completion if balance is sufficient.
- **Credit/Debit Card & UPI**: Processed via secure gateway tokenization.
- **Cash**: Customer hands physical cash to driver; driver taps "Confirm Cash Collected" in driver app to release booking.

---

## 8. Feature: Driver Simulation Test Engine

### 8.1 Objective
A standalone automated simulator service (`/backend/app/simulator.py`) enabling developers and CI/CD pipelines to verify end-to-end trip lifecycles without requiring manual driver interaction.

### 8.2 Capabilities
- Simulates online drivers moving around city coordinates.
- Subscribes to dispatch offers and auto-accepts after 2 seconds.
- Simulates driving from current location to pickup address.
- Sends driver arrival notification.
- Reads booking OTP from test context and submits start trip request.
- Simulates driving along route waypoints to destination.
- Submits trip completion and fare finalization.
