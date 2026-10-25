# User Roles & Access Control Matrix (02_ROLES.md)

## 1. Overview
The platform connects vehicle owners with professional on-demand chauffeurs. The system supports three core operational roles with distinct capabilities, data visibility, and security boundaries.

---

## 2. Role Specifications

### 2.1 Role: Customer (`CUSTOMER`)
- **Description**: Registered car owner or passenger hiring a chauffeur to drive their personal/commercial vehicle.
- **Authentication**: Phone number + SMS OTP verification or email/password with JWT access and refresh tokens.
- **Core Capabilities**:
  - Profile management (name, email, phone, avatar, emergency contacts).
  - Garage management: add, edit, and delete vehicles (Make, Model, Year, Transmission [Manual / Automatic], Fuel type, License Plate).
  - Saved addresses: Home, Work, Frequent destinations with custom labels.
  - Booking creation: Instant ("Drive Now") or Scheduled ("Drive Later"), selecting Hourly City Drive, Round Trip, or Outstation.
  - Real-time tracking: live map tracking of assigned driver with distance and ETA updates.
  - Trip verification: unique 4-digit start-trip OTP presented to the driver to prevent unauthorized pickup.
  - Driver communication: direct in-app messaging and VoIP/masked phone calls.
  - In-trip safety: 1-click Emergency SOS broadcast with live tracking link sent to emergency contacts.
  - Payments & Wallet: digital wallet balance management, promo code application, Razorpay/card/cash payment settlement.
  - Rating & Feedback: post-trip 1-5 star driver rating with categorized badges (e.g., "Smooth Driving", "Punctual", "Courteous") and tip support.

### 2.2 Role: Chauffeur / Driver (`DRIVER`)
- **Description**: Vetted professional driver assigned to drive customer vehicles.
- **Authentication**: Mobile number + OTP or Driver ID + Password with strict background check and verification status checks.
- **Core Capabilities**:
  - Telemetry: publishes high-frequency GPS coordinates (`latitude`, `longitude`, `heading`, `speed`) via WebSocket / Redis GEO.
  - Duty State Toggle: `ONLINE` (available for dispatch), `OFFLINE` (inactive), `BUSY` (on active booking).
  - Dispatch Offer Reception: receives candidate booking offers with pickup distance, customer car transmission type (Crucial: manual vs automatic capability match), estimated duration, and guaranteed fare.
  - Offer Response: Accept or Decline offer within a 30-second countdown window.
  - Trip Lifecycle Execution:
    - `ACCEPT`: transition booking to `DRIVER_ASSIGNED`.
    - `NAVIGATE_TO_PICKUP`: transition to `ON_WAY`.
    - `ARRIVE_AT_PICKUP`: transition to `ARRIVED`, notifies customer.
    - `START_TRIP`: prompts customer for 4-digit OTP; validates with backend to transition to `IN_PROGRESS`.
    - `COMPLETE_TRIP`: ends trip at destination, calculates total elapsed time and distance, displays bill.
    - `COLLECT_PAYMENT`: marks cash received if payment mode is cash.
  - Earnings Dashboard: views daily, weekly, and monthly earnings breakdown, tips, incentives, and trip history.

### 2.3 Role: System Administrator (`ADMIN`)
- **Description**: Operations staff and platform administrators overseeing dispatch health, safety, and business configuration.
- **Authentication**: Email + Multi-factor authentication with RBAC role claim `ADMIN`.
- **Core Capabilities**:
  - Pricing Engine Configuration: manages base fares, hourly thresholds, extra minute rates, night surcharges, outstation allowances, and surge multipliers per city/zone.
  - Live Dispatch Console: visual map of all online drivers, dispatch queue, unassigned bookings, and active trips.
  - Manual Dispatch Override: ability to force-assign a booking to an available driver in case of automated match timeouts.
  - Incident & Dispute Management: handles SOS alerts, trip route deviations, fare adjustments, customer refunds, and driver penalties.
  - User & Driver Verification: review driver licenses, background check approvals, KYC documents, and account suspension/activation.
  - Analytics & Reports: revenue, completed trip volume, average driver ETA, cancellation rate, and customer churn metrics.

---

## 3. Role-Based Access Control (RBAC) Matrix

| Endpoint Domain / Feature | Customer | Driver | Admin |
| :--- | :---: | :---: | :---: |
| Auth: Signup & OTP Verify | Yes | Yes | Admin Portal Only |
| Customer Profile & Garage CRUD | Yes | No | Read/Admin |
| Driver Telemetry Ingestion (GPS) | No | Yes | Read Only |
| Driver Duty Status Toggle | No | Yes | Override |
| Request Fare Estimate | Yes | No | Yes |
| Create Booking Request | Yes | No | Yes (Phone Booking) |
| Accept / Decline Dispatch Offer | No | Yes | Override |
| Start Trip with OTP Validation | No | Yes | Override |
| End Trip & Finalize Fare | No | Yes | Override |
| Live Booking WebSocket Stream | Yes (Own Trip) | Yes (Assigned Trip) | Yes (Global) |
| In-App Chat Messaging | Yes (Own Trip) | Yes (Assigned Trip) | Audit Read |
| Trigger Emergency SOS | Yes | Yes | Alert Receiver |
| Rate & Tip Driver | Yes | No | Moderate |
| Wallet Management & Top-up | Yes | No | Adjust Balance |
| Configure Fare Rates & Surge | No | No | Yes |
| Driver Payouts & Approvals | No | Read Own | Yes |
