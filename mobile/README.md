# ChauffeurX Mobile Application

Clean-room Flutter application for on-demand personal chauffeurs, built to operate with the custom FastAPI backend.

---

## 1. Architecture & Tech Stack

- **Framework**: Flutter 3.47+ / Dart 3.13+
- **Design System**: Material 3 with Midnight Dark Theme (`#0B0F19` background, `#6366F1` indigo primary, `#0EA5E9` sky secondary)
- **State Management**: `flutter_riverpod` (v2.6) with `StateNotifier`
- **Routing**: `go_router` (v14.8) declarative routing with deep parameters
- **Networking**: `dio` (v5.8) with JWT interceptors, automatic silent token refresh, and dual Mock / Real API adapters
- **Real-time Sync**: `web_socket_channel` with snapshot hydration on connect
- **Storage**: `flutter_secure_storage` & `shared_preferences`

---

## 2. Directory Structure

```
lib/
├── core/
│   ├── constants/        # ApiConstants (mock toggle, backend URLs)
│   ├── network/          # ApiClient (Dio instance, JWT AuthInterceptor)
│   ├── router/           # AppRouter (all customer & driver routes)
│   ├── theme/            # AppTheme, AppColors, Google Fonts typography
│   └── widgets/          # AppButton, GlassCard, StateViews
├── features/
│   ├── auth/             # Phone OTP auth, role selector, profile setup
│   ├── booking/          # Review, dispatch radar, live tracking, chat, receipt, rating
│   ├── driver/           # Duty toggle, incoming offers, trip navigation, OTP verification, earnings
│   ├── garage/           # Vehicle management with transmission matching (Auto/Manual)
│   ├── home/             # Map view, service tabs, active ride banner
│   ├── location/         # Autocomplete search & pin-on-map picker
│   ├── safety/           # Rapid SOS hold trigger, 112 helpline, emergency contacts
│   └── wallet/           # Stored value balance, top-up modal, transaction ledger
└── main.dart             # ProviderScope & MaterialApp.router entry
```

---

## 3. How to Run Locally

### 3.1 Run in Demo Mode (Mock Repositories)
By default, `ApiConstants.useMockData` is enabled when backend is unreachable, allowing you to run and demo all screens offline:
```bash
flutter run
```

### 3.2 Run Against the Real FastAPI Backend
1. Ensure the backend is running (`uvicorn app.main:app --port 8000` or Docker Compose).
2. Set your host address in `lib/core/constants/api_constants.dart`:
   - Android Emulator: `http://10.0.2.2:8000/api/v1`
   - iOS Simulator / macOS: `http://127.0.0.1:8000/api/v1`
   - Physical Device: `http://<your-lan-ip>:8000/api/v1`
3. Run the application:
```bash
flutter run --dart-define=API_URL=http://127.0.0.1:8000/api/v1
```

---

## 4. How to Test

Run the widget and integration tests:
```bash
flutter test
```

Run static analysis:
```bash
flutter analyze
```

---

## 5. Build Steps for APK & App Bundle (AAB)

### 5.1 Build Android Release APK
```bash
flutter build apk --release --split-per-abi
```
Output: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

### 5.2 Build Google Play App Bundle (AAB)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`
