# Flutter Mobile Frontend Architecture & Design (09_FRONTEND_DESIGN.md)

This document specifies the technical design, architectural patterns, design system, state management, and project organization for the Flutter client in `/mobile`.

---

## 1. Technology Stack & Key Dependencies

- **Framework**: Flutter 3.x (Dart 3.x) targeting Android, iOS, and Web.
- **State Management**: `flutter_riverpod: ^2.5.1` (compile-time safety, dependency injection, reactive caching).
- **Navigation**: `go_router: ^14.0.0` (declarative URL-based routing, nested shells, deep-linking).
- **HTTP Client**: `dio: ^5.4.3` (interceptors for JWT auto-injection and silent token refresh).
- **Secure Persistence**: `flutter_secure_storage: ^9.0.0` (hardware-backed keychain/keystore token storage).
- **Local Cache**: `shared_preferences: ^2.2.3` (theme preferences, onboarding completion flag).
- **Serialization**: `freezed: ^2.5.1` and `json_serializable: ^6.8.0` (immutable data models, unions, and JSON parsing).
- **Mapping & Geolocation**: `google_maps_flutter: ^2.6.0` (hardware-accelerated map rendering, markers, polylines), `geolocator: ^11.0.0` (device GPS coordinate stream).
- **Design System**: Material 3 with custom high-contrast dark palette, glassmorphism cards, and Google Fonts (`Outfit` / `Inter`).

---

## 2. Feature-First Directory Structure

```
mobile/
├── lib/
│   ├── core/
│   │   ├── constants/            # App constants, API endpoints, asset paths
│   │   ├── network/              # Dio client, auth interceptor, error interceptor
│   │   ├── router/               # go_router definitions, route guards, shell routes
│   │   ├── services/             # WebSocketService, LocationService, StorageService
│   │   ├── theme/                # ColorScheme, Typography, CardThemes, ButtonThemes
│   │   └── widgets/              # Reusable atoms (AppButton, AppTextField, LoadingShimmer)
│   ├── features/
│   │   ├── auth/                 # Authentication, OTP, Profile setup
│   │   │   ├── data/             # AuthApi, AuthRepositoryImpl
│   │   │   ├── domain/           # UserModel, AuthState
│   │   │   └── presentation/     # PhoneScreen, OtpScreen, ProfileSetupScreen
│   │   ├── home/                 # Main map, service selection, nearby drivers
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/     # HomeScreen, MainMapWidget, ServiceSelectorSheet
│   │   ├── garage/               # Customer vehicles (Automatic/Manual transmission)
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/     # GarageScreen, AddVehicleDialog
│   │   ├── booking/              # Fare review, state machine, live ride tracking
│   │   │   ├── data/
│   │   │   ├── domain/           # BookingModel, BookingState, FareEstimate
│   │   │   └── presentation/     # ReviewScreen, RadarScreen, LiveTrackingScreen, ReceiptScreen
│   │   ├── chat/                 # Realtime in-app driver messaging
│   │   ├── wallet/               # Digital wallet, transactions ledger, top-up
│   │   ├── safety/               # Emergency contacts, 1-click SOS broadcast
│   │   └── driver/               # Driver portal (duty toggle, telemetry, offer popup)
│   └── main.dart
```

---

## 3. State Management Architecture

Riverpod providers are organized around business capabilities:
- `authNotifierProvider`: Manages user authentication lifecycle (`Unauthenticated`, `Authenticating`, `Authenticated`, `NewUserSetup`).
- `garageNotifierProvider`: Asynchronous vehicle collection; holds currently selected vehicle for dispatch transmission matching.
- `bookingNotifierProvider`: Mirrors the backend booking state machine. Automatically transitions screens as WebSocket state frames arrive.
- `driverDutyNotifierProvider`: Tracks driver online/offline status and manages background GPS telemetry stream.

---

## 4. Realtime WebSocket Resiliency & Heartbeat

The `WebSocketService` guarantees zero message loss and seamless reconnection:
- **Automatic Reconnection**: Exponential backoff (1s, 2s, 4s, 8s, max 15s).
- **Heartbeat Ping/Pong**: 30-second ping frames to prevent NAT gateway timeouts.
- **Hydration on Reconnect**: Requests instant snapshot from server upon reconnect to heal any dropped intermediate frames.

---

## 5. Aesthetics & Design System Tokens

- **Surface Primary**: Deep Midnight Slate (`#0B0F19`)
- **Surface Secondary**: Elevation Slate (`#1E293B`)
- **Accent Primary**: Electric Indigo (`#6366F1`)
- **Accent Success**: Vibrant Emerald (`#10B981`)
- **Accent Alert / Surge**: Radiant Amber (`#F59E0B`)
- **Accent Error**: Crimson Rose (`#F43F5E`)
- **Glassmorphism**: Backdrop filter blur with 12% border stroke (`Colors.white.withOpacity(0.08)`).
