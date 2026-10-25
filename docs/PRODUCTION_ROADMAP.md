# From Local Demo to Live Production (PRODUCTION_ROADMAP.md)

This document explains what is already fully functional in your project today, and provides simple, step-by-step instructions for connecting real-world third-party services (SMS, Payments, Maps, and App Stores).

---

## 1. What is Already Real vs What is in Sandbox Mode

| Component | Current State | What It Does Today | What Real Production Needs |
| :--- | :--- | :--- | :--- |
| **Backend & Database** | **100% Real Code** | Saves real users, vehicles, trips, and fares into the database. | Just deploy to a cloud server (AWS, Render, or DigitalOcean). |
| **Business Logic** | **100% Real Code** | Pricing math, transmission checks, and booking state guards work fully. | No changes needed. |
| **Mobile App UI** | **100% Real Code** | All 20+ screens, animations, forms, and navigation are real Flutter widgets. | Compile release APK/AAB for App Stores. |
| **SMS Verification** | **Sandbox Mode** | Accepts demo code `123456` so you can test without SMS fees. | Plug in Twilio, AWS SNS, or Firebase SMS API keys. |
| **Payment Gateway** | **Sandbox Mode** | In-app wallet adds simulated credits for instant checkout. | Plug in Stripe or Razorpay API keys. |
| **Map Rendering** | **Custom Canvas** | Shows vector roads, pins, radar sonar, and live movement. | Add a Google Maps API Key for satellite street tiles. |
| **Push Notifications** | **In-App WebSockets** | Real-time alerts work while the app is open. | Add Firebase Cloud Messaging (FCM) for background alerts. |

---

## 2. The 5 Steps to Make It 100% Production Ready

### Step 1: Connect Real SMS (Twilio or Firebase)
*Why: So real customers receive actual SMS verification codes on their physical phones.*
1. Create a free account on **Twilio** (or Firebase Phone Auth).
2. Get your `Account SID` and `Auth Token`.
3. In `backend/app/core/config.py`, add your Twilio credentials.
4. Replace the OTP sender in `backend/app/api/v1/auth.py` with Twilio's single-line client call:
   ```python
   twilio_client.messages.create(body=f"Your ChauffeurX code is {otp}", from_="+1...", to=phone)
   ```

### Step 2: Connect Real Payments (Stripe or Razorpay)
*Why: So customers pay with real debit/credit cards or Apple Pay, and money deposits into your bank.*
1. Create an account on **Stripe** (International) or **Razorpay** (India/Asia).
2. Get your `API Secret Key` and `Publishable Key`.
3. In `backend/app/api/v1/wallet.py`, add the Stripe payment intent hook.
4. In Flutter (`mobile/pubspec.yaml`), add `flutter_stripe` so the customer taps Apple Pay, Google Pay, or types their card directly.

### Step 3: Enable Google Maps API Keys
*Why: To show real Google satellite imagery and street-level road maps.*
1. Open the **Google Cloud Console** and enable:
   - *Maps SDK for Android*
   - *Maps SDK for iOS*
   - *Places API & Directions API*
2. Paste the key into:
   - Android: `mobile/android/app/src/main/AndroidManifest.xml` (`com.google.android.geo.API_KEY`)
   - iOS: `mobile/ios/Runner/AppDelegate.swift` (`GMSServices.provideAPIKey("...")`)

### Step 4: Add Firebase Cloud Messaging (Push Notifications)
*Why: So drivers hear a ringtone even if their phone is locked in their pocket.*
1. Create a project at `console.firebase.google.com`.
2. Download `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS).
3. Drop them into `mobile/android/app/` and `mobile/ios/Runner/`.
4. When a booking is created, the backend sends an FCM push alert directly to the driver's phone.

### Step 5: Deploy the Backend to the Cloud & Publish the App
1. **Host the Backend**:
   - Create a cloud database on **Render**, **Railway**, or **AWS EC2**.
   - Push your `/backend` folder with Docker Compose.
   - Update `ApiConstants.baseUrl` in `mobile/lib/core/constants/api_constants.dart` to your live domain (e.g., `https://api.yourdomain.com`).
2. **Publish the Flutter App**:
   - Android: Run `flutter build appbundle --release` and upload `app-release.aab` to Google Play Console.
   - iOS: Run `flutter build ipa --release` and upload to Apple App Store Connect via Xcode.
