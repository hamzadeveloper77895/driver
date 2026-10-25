# Screen Inventory & UI Specifications (03_SCREENS.md)

This document specifies every screen in the application. For each screen, we specify route, UI layout, interactive elements, input validation rules, and empty/loading/error states.

---

## 1. Customer Application Screens

### 1.1 Splash & Config Screen
- **Route**: `/splash`
- **Purpose**: App initialization, remote config loading, JWT token verification, and routing to Home or Auth.
- **UI Elements**:
  - Animated branding logo (ChauffeurX / DriveFlow).
  - Version indicator (e.g. `v1.0.0`).
  - Subtle glowing progress bar / loading indicator at the bottom.
- **Inputs & Validations**: None (automated).
- **Loading State**: Pulsing app icon with glassmorphism accent backdrop.
- **Empty State**: N/A.
- **Error State**: "Unable to connect to server. Check your internet connection." with a "Retry" button.

### 1.2 Onboarding Walkthrough
- **Route**: `/onboarding`
- **Purpose**: Introduction to on-demand chauffeur services, vehicle safety, and trusted drivers.
- **UI Elements**:
  - Horizontal swipeable carousel with 3 slides:
    1. "Professional Drivers for Your Car"
    2. "Hourly & Outstation Flexibility"
    3. "Live GPS Tracking & Safety Guaranteed"
  - Page indicator dots (smooth transition).
  - "Skip" text button in header.
  - "Get Started" prominent primary button.
- **Inputs & Validations**: Carousel gestures (horizontal drag).
- **Loading State**: Static illustrations preloaded.
- **Empty State**: N/A.
- **Error State**: N/A.

### 1.3 Authentication: Phone Input
- **Route**: `/auth/phone`
- **Purpose**: Mobile number entry for OTP-based passwordless authentication.
- **UI Elements**:
  - Hero illustration with welcoming title: "Enter your mobile number".
  - Country code selector dropdown (default `+91` / `+1`).
  - Phone number text field with clear button.
  - Terms of Service & Privacy Policy disclaimer with active hyperlinks.
  - "Continue" primary button.
- **Inputs & Validations**:
  - `phone`: Required, numbers only, exactly 10 digits for India (`^[6-9]\d{9}$`), or standard E.164 formatting.
- **Loading State**: Button displays circular progress spinner; input fields disabled.
- **Empty State**: Placeholder text: "e.g. 98765 43210".
- **Error State**: Red inline helper text ("Please enter a valid 10-digit mobile number") and shake animation.

### 1.4 Authentication: OTP Verification
- **Route**: `/auth/verify-otp`
- **Purpose**: Verifies 6-digit one-time password sent via SMS.
- **UI Elements**:
  - Header with recipient phone number and "Edit" pencil icon to change number.
  - 6 individual OTP pin boxes with auto-focus and auto-advance.
  - Countdown timer ("Resend OTP in 00:29").
  - "Resend Code via SMS" text button (enabled when timer expires).
  - "Verify & Proceed" CTA button.
- **Inputs & Validations**:
  - `otp`: Exactly 6 numeric digits (`^\d{6}$`).
- **Loading State**: Full-screen semi-transparent overlay with "Verifying OTP...".
- **Empty State**: Empty pin boxes with blinking cursor on box 1.
- **Error State**: Pin boxes highlighted in error red; message: "Incorrect OTP. 3 attempts remaining."

### 1.5 Authentication: Profile Setup (New Users)
- **Route**: `/auth/profile-setup`
- **Purpose**: Captures new user details upon first login.
- **UI Elements**:
  - Avatar picker (camera / gallery selector or preset avatars).
  - First Name and Last Name input fields.
  - Email Address input field (optional/recommended for invoices).
  - Referral / Promo Code text field (optional with "Apply" badge).
  - "Complete Setup" primary button.
- **Inputs & Validations**:
  - `first_name`: Required, min 2 chars, letters only.
  - `last_name`: Optional, min 1 char.
  - `email`: Optional, valid email regex (`^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$`).
- **Loading State**: Button displays loading spinner.
- **Empty State**: Empty input fields with helpful placeholders.
- **Error State**: Field-level validation highlights.

### 1.6 Home Screen & Interactive Map
- **Route**: `/home`
- **Purpose**: Core landing dashboard with interactive map, nearby available chauffeurs, and service category selection.
- **UI Elements**:
  - Top navigation bar: Profile avatar (opens drawer/settings), wallet balance badge, safety shield icon.
  - Full-screen MapView with user current location marker and animated cars representing nearby available drivers.
  - Re-center GPS floating action button.
  - Draggable Bottom Sheet:
    - Service category tabs: "Hourly Drive" (City), "Outstation / Round Trip", "Car Wash / Care".
    - "Where to?" search trigger card with Pickup location prefilled as "Current Location".
    - Quick-select saved addresses pills: "Home", "Work", "+ Add Favorite".
    - Active booking banner (if user has an ongoing or confirmed booking).
- **Inputs & Validations**: Tap to open address search or service tabs.
- **Loading State**: Map skeleton placeholder; shimmering bottom sheet cards.
- **Empty State**: If GPS disabled, banner prompt: "Enable Location Services for accurate pickup".
- **Error State**: "Unable to load nearby drivers. Pull down to refresh."

### 1.7 Location Search & Autocomplete
- **Route**: `/location/search`
- **Purpose**: Search and select pickup and drop-off addresses with autocomplete suggestions.
- **UI Elements**:
  - Dual address input box:
    - Dot icon: "Pickup Address" (defaults to current GPS address).
    - Pin icon: "Drop-off Address" (optional for hourly bookings, required for round trip/outstation).
    - Swap addresses icon button.
  - "Set location on map" action row with map pin icon.
  - List of recent search results.
  - List of saved places (Home, Office).
  - Autocomplete results list with title, subtitle, and distance.
- **Inputs & Validations**:
  - `query`: Min 2 characters to trigger debounced autocomplete (300ms debounce).
- **Loading State**: Shimmering rows for search suggestions.
- **Empty State**: "No recent searches. Type an address or landmark above."
- **Error State**: "No locations found. Try searching for a nearby landmark or pick on map."

### 1.8 Pin-on-Map Address Picker
- **Route**: `/location/map-picker`
- **Purpose**: Fine-tune exact pickup or drop-off pin location by moving the map.
- **UI Elements**:
  - Interactive map with fixed center pin and floating pulse effect.
  - Floating "Locate Me" button.
  - Bottom card showing reverse-geocoded address string and landmark details.
  - "Confirm Location" primary button.
- **Inputs & Validations**: Map drag & zoom.
- **Loading State**: Bottom card shows pulsating shimmer while reverse-geocoding coordinate.
- **Empty State**: Default map view centered at city coordinates.
- **Error State**: "Unable to resolve address. Tap confirm to use coordinates."

### 1.9 Garage & Vehicle Selection
- **Route**: `/garage` and `/garage/add`
- **Purpose**: Select or add customer vehicle to be driven (essential for transmission matching).
- **UI Elements**:
  - List of user's saved vehicles (Card displaying Make, Model, License plate, Transmission badge: `MANUAL` / `AUTOMATIC`, Fuel: `PETROL` / `DIESEL` / `EV`).
  - Radio button for active selection.
  - "+ Add New Vehicle" button.
  - Add Vehicle Modal:
    - Car Brand dropdown (e.g. Maruti, Hyundai, Honda, Toyota, BMW, Tata).
    - Model text field (e.g. City, Creta, Swift, Nexon).
    - Transmission toggle: `Manual` vs `Automatic`.
    - Fuel Type selector pills.
    - Vehicle Registration / Plate number (e.g., `KA 01 AB 1234`).
- **Inputs & Validations**:
  - `brand`: Required.
  - `model`: Required.
  - `transmission`: Required (`MANUAL` or `AUTOMATIC`).
  - `plate_number`: Alphanumeric, uppercase, min 6 chars.
- **Loading State**: Vehicle cards shimmer during fetch.
- **Empty State**: "No cars in your garage yet. Add your vehicle to ensure a driver compatible with your transmission."
- **Error State**: "Failed to save car. Please check fields and try again."

### 1.10 Booking Review & Fare Estimation
- **Route**: `/booking/review`
- **Purpose**: Review trip configuration, estimated duration/distance, transparent fare breakdown, promo code, and payment method before dispatch.
- **UI Elements**:
  - Route preview card: Pickup address -> Drop-off address with estimated driving time.
  - Booking Type toggle: "Now" (Instant dispatch) vs "Schedule for Later" (Date & Time selector).
  - Package / Duration selector: "2 Hours (Base)", "4 Hours", "8 Hours", "Full Day".
  - Selected Vehicle card with "Change" button.
  - Transparent Fare Breakdown Card:
    - Base fare for selected duration (e.g. $25.00 / Rs 399).
    - Night surcharge (if booking falls between 22:00 - 06:00).
    - Taxes & Service fee (GST 18% / Platform fee).
    - Promo discount (if applied).
    - Total Estimated Fare (highlighted large bold typography).
  - Promo code input row with "Apply" button.
  - Payment method selector pill: Wallet / Card / Cash.
  - "Book Driver" prominent floating CTA button.
- **Inputs & Validations**:
  - `pickup_time`: Cannot be in the past.
  - `duration_hours`: Min 2 hours.
  - `car_id`: Required.
- **Loading State**: Calculating fare with skeleton fare summary.
- **Empty State**: N/A.
- **Error State**: "Pricing currently unavailable for this zone. Please try again."

### 1.11 Driver Dispatch Radar / Searching Screen
- **Route**: `/booking/searching/:bookingId`
- **Purpose**: Real-time waiting screen while the dispatch engine locates and broadcasts to nearby eligible chauffeurs.
- **UI Elements**:
  - Radar sonar wave animation with center pulse.
  - Status text: "Searching for drivers nearby matching your vehicle (Automatic/Manual)...".
  - 60-second animated circular countdown timer.
  - Booking summary mini-card (Pickup location, car model).
  - "Cancel Request" outline button.
- **Inputs & Validations**: Tap Cancel triggers confirmation dialog.
- **Loading State**: Continuous sonar radar animation.
- **Empty State**: N/A.
- **Error State**: If timeout expires without match: "No drivers available right now. Would you like to retry or schedule for later?" with "Retry Search" and "Schedule" buttons.

### 1.12 Live Ride Tracking Screen
- **Route**: `/booking/tracking/:bookingId`
- **Purpose**: Main live tracking screen from driver acceptance through trip completion.
- **UI Elements**:
  - Full-screen real-time MapView:
    - Pickup & destination markers.
    - Route polyline with traffic colors.
    - Animated driver vehicle pin updating in real-time with bearing/heading.
  - Floating Top Safety Bar:
    - SOS Emergency Shield button.
    - Share Live Trip Link button.
  - Bottom Trip Status Sheet (Dynamic per state):
    - **Status Badge**:
      - `DRIVER_ASSIGNED`: "Driver Assigned - Arriving in 8 mins"
      - `ON_WAY`: "Driver on the way"
      - `ARRIVED`: "Driver arrived at pickup location"
      - `IN_PROGRESS`: "Trip in progress - Heading to destination"
      - `COMPLETED`: "Trip completed"
    - **Driver Profile Card**:
      - Driver photo avatar, Full Name, Rating (★ 4.9), Total trips.
      - Call driver button (masked call) & In-app Chat icon with unread badge.
    - **Security Verification OTP Card**:
      - "Share this OTP with driver to start trip: `8 4 9 2`" (large high-contrast badge).
    - **Trip Actions**:
      - "Edit Pickup Location" (allowed before arrival).
      - "Cancel Booking" button (with cancellation fee policy warning).
- **Inputs & Validations**: Real-time WebSocket connection to `/ws/trips/:bookingId`.
- **Loading State**: Shimmering driver details and pulsating route line.
- **Empty State**: N/A.
- **Error State**: "Lost connection to live tracking. Reconnecting in 3s..." banner with offline caching.

### 1.13 In-App Driver Chat
- **Route**: `/booking/chat/:bookingId`
- **Purpose**: Instant messaging between customer and assigned chauffeur.
- **UI Elements**:
  - App bar with driver photo, name, and online status dot.
  - Quick canned messages chips ("I am at the gate", "Please wait 5 minutes", "I am wearing a blue shirt").
  - Reverse ListView of chat bubbles (Customer: indigo right-aligned; Driver: slate left-aligned) with timestamps.
  - Bottom input bar: text field, send button.
- **Inputs & Validations**:
  - `message`: Required, min 1 char, max 500 chars.
- **Loading State**: Centered circular progress indicator.
- **Empty State**: "Send a message to your driver regarding pickup instructions."
- **Error State**: "Failed to send message. Tap to retry."

### 1.14 Safety & Emergency SOS Settings
- **Route**: `/safety` and `/safety/emergency-contacts`
- **Purpose**: Manage emergency contacts and trigger rapid SOS dispatch during a ride.
- **UI Elements**:
  - Toggle: "Share trip automatically with emergency contacts".
  - List of emergency contacts (Name, Relationship, Phone number) with delete icon.
  - "+ Add Emergency Contact" button (max 5 contacts).
  - SOS button with 3-second hold-to-activate safeguard.
  - Emergency services quick call button (`112` / `911`).
- **Inputs & Validations**: Contact Name (required), Phone Number (valid 10 digits).
- **Loading State**: Contacts list shimmer.
- **Empty State**: "No emergency contacts added yet. Add trusted contacts for your peace of mind."
- **Error State**: "Unable to save contact. Please verify the phone number."

### 1.15 Trip Completion & Bill Receipt
- **Route**: `/booking/receipt/:bookingId`
- **Purpose**: Transparent invoice breakdown upon trip termination.
- **UI Elements**:
  - Success checkmark animation.
  - Total Fare amount in large bold font.
  - Payment status pill: "Paid via Wallet" / "Cash to be collected: $32.50".
  - Trip Statistics card:
    - Total Duration (e.g. 2 hrs 45 mins).
    - Distance driven (e.g. 34.2 km).
    - Start time & End time.
  - Itemized Invoice list:
    - Base Package (2 hrs)
    - Extra Time (45 mins @ $0.20/min)
    - Night Charges
    - Taxes (GST)
    - Promo Discount (-$5.00)
  - "Email Invoice" button & "Rate Driver" primary button.
- **Inputs & Validations**: None.
- **Loading State**: Receipt details shimmer.
- **Empty State**: N/A.
- **Error State**: "Unable to fetch receipt details. Tap to retry."

### 1.16 Driver Rating & Tipping
- **Route**: `/booking/rate/:bookingId`
- **Purpose**: Post-trip quality feedback and gratuity.
- **UI Elements**:
  - Driver circular avatar with name.
  - 5 interactive rating stars (1 to 5).
  - Feedback chips (dynamically toggled based on score):
    - If 4-5 stars: "Punctual", "Smooth Driving", "Clean & Professional", "Polite".
    - If 1-3 stars: "Late arrival", "Rough driving", "Rude behavior", "Navigation issues".
  - Optional tip pills: "$2.00", "$5.00", "$10.00", "Custom".
  - Text area for optional written review.
  - "Submit Feedback" button.
- **Inputs & Validations**: `rating` required (1 to 5 stars).
- **Loading State**: Submitting feedback spinner.
- **Empty State**: Unselected stars (0/5).
- **Error State**: "Failed to submit rating. Please try again."

### 1.17 Trip History
- **Route**: `/history`
- **Purpose**: Chronological ledger of all past and cancelled bookings.
- **UI Elements**:
  - Tab bar: "All", "Completed", "Cancelled".
  - List of booking cards:
    - Date & Time.
    - Service type (Hourly City / Outstation).
    - Pickup & Drop-off addresses.
    - Driver name & vehicle driven.
    - Total Amount & Status badge (`COMPLETED` in emerald green, `CANCELLED` in red).
    - Tap card navigates to `/history/:bookingId`.
- **Inputs & Validations**: Pull to refresh; infinite scroll pagination.
- **Loading State**: Shimmering card list.
- **Empty State**: "No rides found. Book your first chauffeur today!" with "Book Now" CTA.
- **Error State**: "Unable to load ride history. Tap to reload."

### 1.18 Digital Wallet & Add Money
- **Route**: `/wallet` and `/wallet/add-money`
- **Purpose**: Manage stored value, view transaction ledger, and top up balance.
- **UI Elements**:
  - Gradient balance card: Available Balance, "+ Add Money" button.
  - Preset top-up pills: "+ $25", "+ $50", "+ $100".
  - Custom amount text field.
  - Recent transactions list (Type: Credit/Debit, Amount, Date, Reference Trip ID).
  - "Proceed to Payment" button.
- **Inputs & Validations**: Top-up amount: min $5.00, max $1,000.00.
- **Loading State**: Balance and transactions shimmer.
- **Empty State**: "No transactions yet. Add money for 1-click seamless booking checkouts."
- **Error State**: "Payment failed. Your account was not charged. Try again."

---

## 2. Driver Application Screens

### 2.1 Driver Dashboard & Duty Toggle
- **Route**: `/driver/dashboard`
- **Purpose**: Driver home screen with online/offline toggle, today's earnings, and radar receiver.
- **UI Elements**:
  - Header: Driver photo, rating badge, Today's Earnings total ($142.50 / 4 trips).
  - Large interactive Duty Switch: `GO ONLINE` (Emerald Green) vs `GO OFFLINE` (Slate).
  - MapView showing driver current location.
  - Performance metrics cards: Acceptance Rate (96%), Completion Rate (100%), Customer Rating (4.95).
  - Active booking bar (if currently engaged in a trip).
- **Inputs & Validations**: Duty toggle initiates location telemetry service.
- **Loading State**: GPS lock indicator.
- **Empty State**: When offline: "You are currently OFFLINE. Go online to receive trip offers."
- **Error State**: "GPS signal weak. Move outdoors for accurate tracking."

### 2.2 Incoming Dispatch Offer Popup
- **Route**: Modal dialog on top of `/driver/dashboard`
- **Purpose**: Broadcasts new ride request with full trip facts and countdown timer.
- **UI Elements**:
  - Floating high-priority card with pulsing border.
  - Countdown circular progress timer (30 seconds to respond).
  - Audio chime alert and haptic vibration.
  - Pickup Distance & ETA (e.g., "1.8 km away • 5 min drive").
  - Customer Vehicle Badge: **"AUTOMATIC TRANSMISSION"** (crucial verification) & Car model (e.g. Honda City).
  - Estimated Duration & Guaranteed Earning (e.g. "4 Hours • $48.00").
  - Pickup landmark address.
  - Dual action buttons: "Decline" (gray) and "Accept Trip" (vibrant emerald).
- **Inputs & Validations**: Tap Accept or Decline before 30-second expiry.
- **Loading State**: Accepting trip spinner.
- **Empty State**: Dismissed automatically when timer reaches zero.
- **Error State**: "Offer expired or accepted by another driver."

### 2.3 Driver Active Trip Navigation
- **Route**: `/driver/trip/:bookingId`
- **Purpose**: Step-by-step trip workflow guide for the assigned chauffeur.
- **UI Elements**:
  - Live MapView with turn-by-turn route to Pickup or Drop-off.
  - Dynamic Action Button:
    - Step 1: "Arrived at Pickup Location" (notifies customer).
    - Step 2: "Start Trip" (prompts for Customer OTP).
    - Step 3: "End Trip at Destination".
  - Customer info bar: Customer name, call button, chat button.
  - Vehicle details reminder card (License plate, car color, fuel type).
- **Inputs & Validations**: State machine sequential progression.
- **Loading State**: Action button spinner.
- **Empty State**: N/A.
- **Error State**: Network disconnection warning banner with local cache fallback.

### 2.4 Start Trip OTP Input Dialog
- **Route**: Modal dialog on `/driver/trip/:bookingId`
- **Purpose**: Prevents fraudulent trip start by requiring customer's unique 4-digit code.
- **UI Elements**:
  - Title: "Enter 4-Digit Customer OTP".
  - 4 PIN input boxes with numeric keypad.
  - "Verify & Start Trip" button.
- **Inputs & Validations**: Exactly 4 digits matching backend session.
- **Loading State**: Verifying OTP spinner.
- **Empty State**: Blank 4 boxes.
- **Error State**: Red highlight: "Invalid OTP. Please ask the customer to check their app."

### 2.5 Driver Trip Summary & Fare Collection
- **Route**: `/driver/trip-summary/:bookingId`
- **Purpose**: Shows final fare, extra hours driven, and cash collection instructions.
- **UI Elements**:
  - Trip completed banner.
  - Final Fare Display.
  - Payment Method indicator:
    - If Digital/Wallet: "Payment settled automatically. Do not collect cash."
    - If Cash: **"COLLECT CASH FROM CUSTOMER: $38.00"** (bold amber alert).
  - "Confirm Cash Collected" check button (for cash rides).
  - "Back to Dashboard" button.
- **Inputs & Validations**: Confirm cash checkbox required if payment mode is cash.
- **Loading State**: Finalizing trip spinner.
- **Empty State**: N/A.
- **Error State**: "Network error settling fare. Cached locally."

### 2.6 Driver Earnings & Payouts Ledger
- **Route**: `/driver/earnings`
- **Purpose**: Financial tracking for chauffeurs.
- **UI Elements**:
  - Date filter tabs: "Today", "This Week", "This Month".
  - Total Net Earnings, Hours Online, Trips Completed.
  - List of completed trips with individual fares and tips.
  - Bank Account / Payouts status card.
- **Inputs & Validations**: Pull to refresh.
- **Loading State**: Financial summary shimmer.
- **Empty State**: "No earnings for the selected period."
- **Error State**: "Unable to load earnings. Tap to retry."
