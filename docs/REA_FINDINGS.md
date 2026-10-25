# REA Reverse Engineering Findings (REA_FINDINGS.md)

## 1. Executive Summary & Target Profile
- **Target Artifact**: `driveu-12-39-0.apk` (Size: 64,670,765 bytes / ~61.7 MB)
- **SHA-256 Digest**: `8990706f6797a3cb1fedf89573cf2bbd84a32a14dfca7c2385bec3a0a5a7c0f7`
- **Application ID / Package**: `com.humblemobile.consumer`
- **Version**: VersionCode `304`, VersionName `12.39.0`
- **Platform Compilations**: compileSdkVersion `36` (Android 16), targetSdkVersion `35` (Android 15), minSdkVersion `26` (Android 8.0 Oreo)

## 2. Framework & Architecture Detection
REA MCP tool `identify_flutter_build` (Evidence ID: `ev_0cba69153c27d23d522b053c8312e5e884df6c3644ef24f4f777fef3519f2a2b`) confirmed:
- `flutter_detected: false`
- No `libapp.so` Dart AOT payload is present.
- The target is a **Native Android Application** built with Kotlin and Java using Multi-Dex (`classes.dex` through `classes5.dex`, total dex footprint ~43.5 MB).
- Application Architecture: Clean Architecture pattern with `domain/`, `data/`, and `presentation/` layers, Jetpack ViewModels, LiveData/StateFlow, Dagger/Hilt dependency injection, Retrofit 2 + OkHttp 3 HTTP networking, ViewBinding/DataBinding, and Google Play Services Location.

## 3. Manifest Analysis & Components Inventory

### 3.1 Application Entry & Launcher Activities
- **Root Application Class**: `com.humblemobile.consumer.AppController` (subclasses `android.app.Application`)
- **Main Launcher Activity**:
  - `com.humblemobile.consumer.activity.ConfigScreenActivity`
  - Action: `android.intent.action.MAIN`
  - Category: `android.intent.category.LAUNCHER`
  - Purpose: Bootstrap splash screen, remote config loading (`/appConfig`), session token check, and permission pre-checks.
- **Authentication Entry**:
  - `com.humblemobile.consumer.activity.BaseSignInSignUpActivity` (Hosts `LoginFragment`, `VerifyNumberFragment`, `SignUpFragment`)
- **Main Map / Home Host**:
  - `com.humblemobile.consumer.activity.LaunchBaseDrawerActivity` (Hosts navigation drawer, `MainMapFragment`, bottom sheet booking widgets)

### 3.2 Key Activities by Functional Domain
1. **Booking & Dispatch Flow**:
   - `com.humblemobile.consumer.home.DUHomeLocationSearchActivity`: Pickup & drop-off address autocomplete search.
   - `com.humblemobile.consumer.home.DUHomeLocationMapSearchActivity`: Pin drop on interactive map with reverse geocoding.
   - `com.humblemobile.consumer.home.DUBookingReviewScreenActivity` / `ReviewActivity`: Fare calculation, service type selection (One-Way, Round Trip, Outstation), vehicle selection, date/time picker, promo codes, wallet deduction, booking confirmation.
   - `com.humblemobile.consumer.activity.BookingTrackingV3Activity`: Live ride tracking with driver location on map, driver details, OTP display, trip status banner, call/chat buttons, emergency SOS, bill breakdown.
   - `com.humblemobile.consumer.activity.DUEditPickupLocationMapActivity`: Edit pickup location while driver is en route.
2. **Driver Communication & Safety**:
   - `com.humblemobile.consumer.chat.DUDriverChatActivity`: In-app realtime text messaging with assigned driver.
   - `com.humblemobile.consumer.clean_arch.presentation.ui.safety_settings.SafetySettingsActivity`: Ride sharing, SOS configuration.
   - `com.humblemobile.consumer.clean_arch.presentation.ui.safety_settings.EmergencyContactsActivity`: Manage emergency SOS contact numbers.
   - `com.humblemobile.consumer.activity.DUDriverProfileActivity`: Driver profile, rating, total trips, experience badges, driver verification status.
3. **Payments & Wallet**:
   - `com.humblemobile.consumer.clean_arch.presentation.ui.payment_options.DUNewPaymentBaseActivity`: Payment options screen (UPI, Cards, NetBanking, DU Wallet, Cash).
   - `com.humblemobile.consumer.clean_arch.presentation.ui.payment_options.PaymentStatusActivity`: Realtime payment verification and transaction status.
   - `com.humblemobile.consumer.activity.DUWalletActivity` & `WalletAddMoneyActivity`: Stored-value wallet balance, recharge, transactions ledger.
   - `com.razorpay.CheckoutActivity`: Razorpay SDK payment sheet.
4. **Garage & Vehicles**:
   - `com.humblemobile.consumer.activity.DUMyGarageBaseActivity`: Customer car management (Make, Model, Transmission [Manual/Automatic], Fuel type).
   - `com.humblemobile.consumer.activity.OnboardingGarageCarActivity`: New vehicle registration step during onboarding or booking.
5. **Trip History & Invoices**:
   - `com.humblemobile.consumer.activity.DUPastOrderBookingDetailsActivity`: Detailed receipt, route map, fare breakdown (base fare, extra minutes, night charges, GST, toll/parking), invoice email trigger.
   - `com.humblemobile.consumer.activity.HistoryDetailsActivity`: Driver rating (1 to 5 stars + feedback tags), driver tipping.
6. **Value Added Services**:
   - `com.humblemobile.consumer.activity.DUCarWashActivity` & `CarServiceActivity`: On-demand doorstep car cleaning and servicing.

### 3.3 Services
- `com.humblemobile.consumer.receiver.MyFCMMessagingListener`: Firebase Cloud Messaging service for push notifications (dispatch alerts, trip state changes, driver arrival, chat messages).
- `androidx.work.impl.background.systemjob.SystemJobService`: WorkManager background synchronization.
- `com.google.android.gms.metadata`: Google Play Services metadata.

### 3.4 Broadcast Receivers
- `com.humblemobile.consumer.receiver.BookingStatusAlarmReceiver`: Periodic local polling and trip status watchdog.
- `com.google.firebase.iid.FirebaseInstanceIdReceiver`: FCM token rotation.
- `androidx.work.impl.diagnostics.DiagnosticsReceiver`: WorkManager maintenance.

### 3.5 Permissions Declared
- `android.permission.INTERNET`: Backend API and WebSocket communication.
- `android.permission.ACCESS_FINE_LOCATION` & `ACCESS_COARSE_LOCATION`: Live pickup location detection and route tracking.
- `android.permission.ACCESS_NETWORK_STATE` & `ACCESS_WIFI_STATE`: Network connectivity monitoring.
- `android.permission.CALL_PHONE`: Direct click-to-call driver and customer care.
- `android.permission.POST_NOTIFICATIONS`: Android 13+ push notifications.
- `android.permission.WAKE_LOCK`: Keep socket and GPS tracking active during rides.
- `android.permission.VIBRATE`: Haptic feedback on driver dispatch and ride state change.

### 3.6 Third-Party SDKs Detected in Binary
- **Push & Engagement**: Firebase Cloud Messaging (FCM), CleverTap (`CLEVERTAP_ACCOUNT_ID: RZ7-57R-676Z`), AppsFlyer.
- **Analytics & Observability**: Firebase Crashlytics, Firebase Performance, PostHog.
- **Payments**: Razorpay Android SDK, Juspay HyperSDK.
- **Mapping & Geocoding**: Google Maps Android SDK, Google Places API, MapMyIndia.
- **Networking & Serialization**: Retrofit 2, OkHttp 3, Gson / Moshi.
