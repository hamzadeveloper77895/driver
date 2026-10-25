# End-to-End Build Plan & Execution Checklist (10_BUILD_PLAN.md)

This checklist outlines the sequential implementation stages, testing gates, and verification criteria for building both the FastAPI backend and Flutter mobile application.

---

## Phase 1: Reverse Engineering & System Design [COMPLETED]
- [x] Extract and inspect `driveu-12-39-0.apk` using REA MCP tools (`open_binary`, `identify_flutter_build`, `inspect_artifact`, `inspect_analysis_view`).
- [x] Detect underlying framework: Native Android Multi-Dex Kotlin/Java Clean Architecture (`flutter_detected: false`).
- [x] Analyze `AndroidManifest.xml`: activities, services, receivers, permissions, and SDKs.
- [x] Document REA findings in `/docs/REA_FINDINGS.md`.
- [x] Document user roles and RBAC in `/docs/02_ROLES.md`.
- [x] Document screen inventory with UI elements, inputs, validations, and states in `/docs/03_SCREENS.md`.
- [x] Generate Mermaid navigation hierarchy and route map in `/docs/04_NAVIGATION.md`.
- [x] Document feature workflows in `/docs/05_FEATURES.md`.
- [x] Formalize booking state machine and transitions in `/docs/06_STATE_MACHINE.md`.
- [x] Design relational data models and ER diagram in `/docs/07_DATA_MODELS.md`.
- [x] Author clean-room OpenAPI 3.1 contract in `/openapi/openapi.yaml`.
- [x] Author backend architecture in `/docs/08_BACKEND_DESIGN.md`.
- [x] Author Flutter frontend architecture in `/docs/09_FRONTEND_DESIGN.md`.
- [x] Log all design decisions in `/docs/DECISIONS.md` and assumptions in `/docs/ASSUMPTIONS.md`.

---

## Phase 2: FastAPI Backend Implementation (`/backend`) [COMPLETED]
- [x] **2.1 Scaffold & Infrastructure**:
  - Python 3.12 virtual environment setup with all required dependencies.
  - Docker Compose configuration (`docker-compose.yml`) for PostgreSQL 16 and Redis 7.
  - Core app settings with Pydantic Settings (`app/core/config.py`).
  - Async database engine & session dependency (`app/core/database.py`).
  - Redis connection pool manager with FakeRedis in-memory fallback (`app/core/redis.py`).
  - Root application with CORS, exception handlers, and `/api/v1/health` endpoint.
- [x] **2.2 Data Models, Migrations & Seeds**:
  - SQLAlchemy 2.0 async declarative models (`User`, `CustomerProfile`, `DriverProfile`, `Vehicle`, `Booking`, `PricingRule`, `Wallet`, `WalletTransaction`, `ChatMessage`, `DriverRating`).
  - Database initialization script & seed data (`app/seeds.py` with pricing rules, sample drivers, and vehicles).
- [x] **2.3 Authentication & RBAC**:
  - SMS OTP generator and Redis store with rate limiting.
  - JWT token manager (Access + Refresh tokens) with password hashing support.
  - Auth routes (`/request-otp`, `/verify-otp`, `/refresh-token`, `/me`).
  - Security dependencies (`get_current_user`, `require_role`).
- [x] **2.4 Garage & Profiles**:
  - Vehicle management endpoints (Create, List, Delete, Default toggle) with `MANUAL`/`AUTOMATIC` validation.
  - Emergency contact endpoints.
- [x] **2.5 Pricing Engine**:
  - Configurable fare calculator (Base package hours, extra minutes, night surcharges, taxes, surge multiplier).
  - Estimate endpoint (`/api/v1/pricing/estimate`).
- [x] **2.6 Booking State Machine & Dispatch**:
  - Booking state transition engine enforcing strict preconditions and side effects (`app/services/state_machine.py`).
  - Unit tests covering 100% of state transitions (`DRAFT -> PENDING -> DRIVER_ASSIGNED -> ON_WAY -> ARRIVED -> IN_PROGRESS -> COMPLETED -> DISPUTED`).
  - Redis GEO driver dispatch service with radius escalation and transmission matching.
  - Distributed lock preventing race conditions on offer acceptance.
- [x] **2.7 Realtime WebSockets & Telemetry**:
  - WebSocket connection manager with Redis Pub/Sub integration (`app/services/websocket_manager.py`).
  - Live trip event broadcasting (`HYDRATION_SNAPSHOT`, `DRIVER_LOCATION_UPDATE`, `TRIP_STARTED`, `TRIP_COMPLETED`).
  - Driver telemetry endpoint with Redis GEO update.
- [x] **2.8 Driver Simulation Engine**:
  - Autonomous driver simulator (`app/simulator.py`) for automated booking lifecycle testing.
- [x] **2.9 Backend Verification**:
  - Executed test suite (`pytest`): 25/25 tests passed in 1.25s.
  - Run autonomous simulator verifying end-to-end trip completion.
  - Documented operational runbook in `/docs/RUNBOOK.md` and `backend/README.md`.

---

## Phase 3: Flutter Mobile Application Implementation (`/mobile`) [COMPLETED]
- [x] **3.1 Project Scaffold & Foundation**:
  - Flutter project setup with dependencies (`riverpod`, `go_router`, `dio`, `flutter_secure_storage`, `google_fonts`, `web_socket_channel`).
  - Material 3 custom theme (Deep Midnight Slate, Electric Indigo, Emerald Green in `app_theme.dart`).
  - Feature-first folder structure (`core/`, `features/<name>/data, domain, presentation`).
- [x] **3.2 Networking, Storage & Mock Repositories**:
  - Dio HTTP client with JWT interceptor and automatic token refresh (`api_client.dart`).
  - Dual repository pattern: Mock repositories and Real API repositories with `useMockData` toggle.
- [x] **3.3 Authentication & Onboarding Flow**:
  - Animated Splash screen (`SplashScreen`) with token check.
  - Onboarding walkthrough carousel (`OnboardingScreen`).
  - Phone entry screen (`PhoneAuthScreen`) with role switcher (Customer vs Driver).
  - 6-digit OTP verification screen (`OtpVerificationScreen`) with countdown timer.
  - New user profile completion (`ProfileSetupScreen`).
- [x] **3.4 Customer Home & Location Selection**:
  - Interactive MapView screen (`HomeScreen`) with GPS current location and nearby drivers.
  - Draggable bottom sheet with service package tabs.
  - Autocomplete location search (`LocationSearchScreen`) & Pin-on-map picker (`MapPinPickerScreen`).
- [x] **3.5 Garage & Booking Review**:
  - Garage vehicle selector (`GarageScreen`) with transmission type badges and add vehicle sheet.
  - Booking review screen (`BookingReviewScreen`) with live fare computation.
  - Dispatch radar searching screen (`DriverSearchScreen`) with sonar pulse animation.
- [x] **3.6 Live Ride Tracking & Safety**:
  - Live tracking screen (`TripTrackingScreen`) with real-time driver vehicle animation and bearing rotation.
  - Dynamic status sheet and high-contrast 4-digit OTP card.
  - In-app driver chat screen (`ChatScreen`).
  - Emergency SOS broadcast trigger and contact management (`SafetyScreen`).
  - Trip completion receipt screen (`TripReceiptScreen`) and Driver rating/tipping (`RatingScreen`).
  - Trip history ledger (`TripHistoryScreen`).
- [x] **3.7 Driver Operations Portal**:
  - Driver dashboard (`DriverDashboardScreen`) with online/offline toggle and GPS telemetry stream.
  - Incoming dispatch offer modal dialog with 30s countdown timer.
  - Driver trip navigation screen with customer arrival notification and Start-Trip OTP entry dialog (`DriverTripScreen`).
  - Fare collection confirmation and driver earnings ledger (`DriverEarningsScreen`).
- [x] **3.8 Mobile Verification & Quality Assurance**:
  - Unit and widget tests for core state notifiers and screen widgets: 7/7 tests passed.
  - Happy-path integration test verifying end-to-end booking flow.
  - Run `flutter analyze`: 0 errors, 0 fatal warnings.
  - Prepared APK/AAB build instructions and mobile README in `mobile/README.md`.

---

## Phase 4: Final Verification & Handover [COMPLETED]
- [x] Run full system verification (Backend: 25/25 tests passed; Frontend: 7/7 tests passed, analyze clean).
- [x] Deliver concise 5-line final summary with exact run commands.
