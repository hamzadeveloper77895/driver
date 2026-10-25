# ChauffeurX System Documentation & Architecture Guide (APP_EXPLANATION.md)

## 1. System Overview
**ChauffeurX** is a complete, clean-room reimagination of on-demand chauffeur services (inspired by reverse-engineering `driveu-12-39-0.apk`). Unlike standard ride-hailing where drivers bring their own cars, ChauffeurX dispatches certified professional chauffeurs to drive the **customer's personal vehicle**.

## 2. Reverse Engineering Insights (REA Analysis)
- **Framework Detection**: Analyzed with REA MCP tools (`open_binary`, `identify_flutter_build`). Confirmed native Android Kotlin/Java multi-dex architecture (`com.humblemobile.consumer`).
- **Core Engineering Constraint**: Because chauffeurs operate the customer's vehicle, **Transmission Compatibility** (`MANUAL` vs `AUTOMATIC`) is a non-negotiable dispatch constraint.
- **Trip Security Constraint**: A server-generated 4-digit **Start-Trip OTP** is mandated to eliminate trip start fraud before any metering commences.
- **Clean-Room Enforcement**: Zero copied assets, proprietary tokens, or original URLs. 100% original FastAPI backend and Flutter codebase.

## 3. User Roles & Access Control (RBAC)
1. **Customer**: Registers via Phone OTP, manages garage vehicles, checks fare quotes, books chauffeurs, tracks rides live via WebSockets, chats in-app, triggers SOS, and pays via digital wallet.
2. **Driver Partner**: Toggles duty status (`ONLINE`/`OFFLINE`), broadcasts real-time GPS telemetry, receives radius-escalated dispatch offers, inputs customer OTP to begin trips, and tracks daily earnings.
3. **Admin**: Oversees platform rules, audit logs, pricing rules, dispute resolution, and driver verification.

## 4. Key Architectural Features
1. **My Garage & Transmission Matching**: Customers save their vehicles with transmission classification. The dispatch engine filters out drivers not certified for that transmission type.
2. **Dynamic Pricing Engine**: Computes base duration fares (2, 4, 8, 12 hrs), night surcharges (22:00–06:00), statutory taxes (18% GST), surge multipliers, and cancellation tiers.
3. **Redis GEO Dispatch Engine**: Geohash radius escalation (3km -> 6km -> 10km) broadcasts requests to idle nearby drivers with a 30-second response lock to prevent race conditions.
4. **Finite State Machine**: Strict sequential transitions: `DRAFT` -> `PENDING` -> `DRIVER_ASSIGNED` -> `ON_WAY` -> `ARRIVED` -> `IN_PROGRESS` -> `COMPLETED` (or `CANCELLED`/`DISPUTED`).
5. **Real-Time WebSocket Sync**: Bi-directional communication channel over Redis Pub/Sub providing live driver coordinate updates, bearing rotations, and state change snapshots on reconnect.
6. **In-App Safety & Emergency SOS**: 3-second hold emergency trigger, automated live-location dispatch to emergency contacts, and direct 112 emergency helpline integration.
7. **Autonomous Driver Simulator**: Background engine simulating realistic chauffeur movement, arrival, and OTP handshakes for automated testing.

## 5. Technology Stack
- **Backend**: FastAPI (Python 3.12), SQLAlchemy 2 (async), Pydantic v2, Alembic, PostgreSQL 16 + Redis 7 (production) / SQLite (`aiosqlite`) + FakeRedis (zero-dependency local development).
- **Mobile Frontend**: Flutter 3.47+ / Dart 3.13+, Material 3 Midnight Theme, Riverpod 2.6 (StateNotifier), GoRouter 14.8, Dio 5.8 with JWT auth interceptors and silent refresh, dual Mock/API repository pattern.
- **API Specification**: Standardized OpenAPI 3.1 specification (`/openapi/openapi.yaml`).

## 6. How to Run
- **Backend**: `cd backend && source .venv/bin/activate && uvicorn app.main:app --port 8000` (test suite: `pytest -v tests` -> 25/25 passed).
- **Frontend**: `cd mobile && flutter run` (test suite: `flutter test` -> 7/7 passed, `flutter analyze` -> clean).
