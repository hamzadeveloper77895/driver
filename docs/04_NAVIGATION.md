# Application Navigation Map (04_NAVIGATION.md)

This document maps out the entire screen navigation hierarchy, route paths, transitions, and state triggers for both Customer and Driver applications using Mermaid diagrams.

---

## 1. Complete Application Navigation Hierarchy

```mermaid
flowchart TD
    SPLASH["/splash (Splash Screen)"] --> CHECK_AUTH{"Token Valid?"}
    
    %% Auth Flow
    CHECK_AUTH -- "No" --> ONBOARDING["/onboarding (Walkthrough Carousel)"]
    ONBOARDING --> PHONE_AUTH["/auth/phone (Mobile Number Input)"]
    PHONE_AUTH --> VERIFY_OTP["/auth/verify-otp (6-Digit OTP)"]
    VERIFY_OTP --> CHECK_PROFILE{"Profile Exists?"}
    CHECK_PROFILE -- "New User" --> PROFILE_SETUP["/auth/profile-setup (Name, Email, Car)"]
    PROFILE_SETUP --> HOME["/home (Customer Home Map)"]
    
    %% Main Customer Branch
    CHECK_AUTH -- "Yes (Customer)" --> HOME
    CHECK_AUTH -- "Yes (Driver)" --> DRIVER_HOME["/driver/dashboard (Driver Portal)"]
    
    %% Customer Navigation
    HOME --> DRAWER["Side Drawer / Settings"]
    DRAWER --> GARAGE["/garage (My Vehicles)"]
    DRAWER --> HISTORY["/history (Trip History)"]
    DRAWER --> WALLET["/wallet (Digital Wallet)"]
    DRAWER --> SAFETY["/safety (Emergency Contacts & SOS)"]
    DRAWER --> HELP["/help (FAQ & Support)"]
    
    GARAGE --> ADD_CAR["/garage/add (Add Vehicle Modal)"]
    HISTORY --> TRIP_DETAIL["/history/:bookingId (Past Trip Breakdown)"]
    WALLET --> ADD_MONEY["/wallet/add-money (Top-up Balance)"]
    
    %% Booking Creation Sub-flow
    HOME --> SEARCH_LOC["/location/search (Pickup & Drop Search)"]
    SEARCH_LOC --> MAP_PICKER["/location/map-picker (Pin on Map)"]
    MAP_PICKER --> SEARCH_LOC
    SEARCH_LOC --> REVIEW["/booking/review (Fare Estimate & Review)"]
    
    REVIEW --> PROMO["/booking/promos (Promo Code Selector)"]
    REVIEW --> SELECT_CAR["/garage (Select/Add Car)"]
    PROMO --> REVIEW
    SELECT_CAR --> REVIEW
    
    REVIEW --> DISPATCH_RADAR["/booking/searching/:bookingId (Radar Radar Screen)"]
    
    %% Active Ride Lifecycle
    DISPATCH_RADAR -- "Driver Accepts" --> LIVE_TRACK["/booking/tracking/:bookingId (Live Trip Tracking)"]
    DISPATCH_RADAR -- "Timeout / No Driver" --> RETRY_DIALOG["No Driver Popup"]
    RETRY_DIALOG --> REVIEW
    
    LIVE_TRACK --> CHAT["/booking/chat/:bookingId (In-App Driver Chat)"]
    LIVE_TRACK --> DRIVER_INFO["/driver/profile/:driverId (Driver Profile Sheet)"]
    LIVE_TRACK --> EDIT_PICKUP["/booking/edit-pickup (Fine Tune Pickup)"]
    
    LIVE_TRACK -- "Trip Completed" --> RECEIPT["/booking/receipt/:bookingId (Trip Bill)"]
    RECEIPT --> RATE_TIP["/booking/rate/:bookingId (Rating & Tip)"]
    RATE_TIP --> HOME
    
    %% Driver Flow
    DRIVER_HOME --> EARNINGS["/driver/earnings (Daily Ledger)"]
    DRIVER_HOME --> DRIVER_HISTORY["/driver/history (Completed Trips)"]
    DRIVER_HOME -- "Incoming Dispatch" --> OFFER_MODAL["Dispatch Offer Modal (30s)"]
    OFFER_MODAL -- "Accept" --> DRIVER_TRIP["/driver/trip/:bookingId (Turn-by-Turn Guide)"]
    OFFER_MODAL -- "Decline/Expire" --> DRIVER_HOME
    
    DRIVER_TRIP --> START_OTP_MODAL["Start Trip OTP Dialog"]
    START_OTP_MODAL --> DRIVER_TRIP
    DRIVER_TRIP -- "End Trip" --> DRIVER_SUMMARY["/driver/trip-summary/:bookingId (Fare & Cash Collection)"]
    DRIVER_SUMMARY --> DRIVER_HOME
```

---

## 2. Booking State & Screen Synchronization Map

```mermaid
stateDiagram-v2
    [*] --> Screen_Home : User opens app
    Screen_Home --> Screen_SearchAddress : Tap 'Where to?'
    Screen_SearchAddress --> Screen_Review : Selected Destination & Time
    Screen_Review --> Screen_DispatchRadar : Tap 'Book Chauffeur'
    
    state Screen_DispatchRadar {
        [*] --> Polling_Drivers
        Polling_Drivers --> Driver_Assigned : WebSocket event 'driver_assigned'
        Polling_Drivers --> No_Drivers_Found : Timeout 60s
    }
    
    No_Drivers_Found --> Screen_Review : Retry / Reconfigure
    Driver_Assigned --> Screen_LiveTracking : Navigate to live tracking
    
    state Screen_LiveTracking {
        state "State: DRIVER_ASSIGNED" as StAssigned
        state "State: ON_WAY" as StOnWay
        state "State: ARRIVED" as StArrived
        state "State: IN_PROGRESS" as StInProgress
        
        [*] --> StAssigned
        StAssigned --> StOnWay : Driver en route
        StOnWay --> StArrived : Driver at pickup location
        StArrived --> StInProgress : Customer OTP verified by driver
    }
    
    StInProgress --> Screen_Receipt : Driver ends trip & fare finalized
    Screen_Receipt --> Screen_Rating : Tap 'Rate Driver'
    Screen_Rating --> Screen_Home : Submit rating / Done
```

---

## 3. Route Configuration Table (`go_router`)

| Route Path | Screen Widget | Guard / Requirement | Transitions |
| :--- | :--- | :--- | :--- |
| `/splash` | `SplashScreen` | None | Replace to `/home` or `/onboarding` |
| `/onboarding` | `OnboardingScreen` | Unauthenticated | Slide to `/auth/phone` |
| `/auth/phone` | `PhoneAuthScreen` | Unauthenticated | Push `/auth/verify-otp` |
| `/auth/verify-otp` | `OtpVerificationScreen` | Unauthenticated | Replace to `/home` or `/auth/profile-setup` |
| `/auth/profile-setup` | `ProfileSetupScreen` | Authenticated (New) | Replace to `/home` |
| `/home` | `HomeScreen` | Authenticated (Customer) | Bottom sheet / Push routes |
| `/location/search` | `LocationSearchScreen` | Authenticated | Push `/booking/review` |
| `/location/map-picker`| `MapPinPickerScreen` | Authenticated | Pop with coordinates |
| `/garage` | `GarageScreen` | Authenticated | Push `/garage/add` |
| `/garage/add` | `AddVehicleModal` | Authenticated | Pop on save |
| `/booking/review` | `BookingReviewScreen` | Authenticated | Push `/booking/searching/:id` |
| `/booking/searching/:id` | `DriverSearchScreen` | Authenticated | Replace to `/booking/tracking/:id` |
| `/booking/tracking/:id` | `TripTrackingScreen` | Authenticated | Replace to `/booking/receipt/:id` |
| `/booking/chat/:id` | `ChatScreen` | Authenticated | Push / Pop |
| `/booking/receipt/:id`| `TripReceiptScreen` | Authenticated | Push `/booking/rate/:id` |
| `/booking/rate/:id` | `RatingTipScreen` | Authenticated | Pop to `/home` |
| `/history` | `TripHistoryScreen` | Authenticated | Push `/history/:id` |
| `/wallet` | `WalletScreen` | Authenticated | Push `/wallet/add-money` |
| `/safety` | `SafetySettingsScreen`| Authenticated | Push `/safety/emergency-contacts` |
| `/driver/dashboard` | `DriverHomeScreen` | Authenticated (Driver) | Bottom sheet / Full-screen trip |
| `/driver/trip/:id` | `DriverTripScreen` | Authenticated (Driver) | Replace to `/driver/trip-summary/:id` |
| `/driver/earnings` | `DriverEarningsScreen`| Authenticated (Driver) | Push / Pop |
