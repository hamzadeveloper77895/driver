# Role Workflows: Customer vs Driver Partner

## Overview
ChauffeurX separates the application lifecycle into two distinct personas:
1. **Customer App (`CUSTOMER`)**:
   - Hourly & package driver booking (Indiranagar, Airport, Outstation).
   - Garage management: adding vehicles (transmission, fuel type, plate number).
   - Dynamic fare estimates and start-trip OTP verification code display.
   - Live telemetry tracking on interactive radar map.
   - Digital wallet balance & top-ups.

2. **Driver Partner App (`DRIVER`)**:
   - **Driver Dashboard**: Duty status toggle (`ONLINE` / `OFFLINE`).
   - **Incoming Trip Offer Bottom Sheet**: Acceptance countdown timer, pickup distance, duration package, earnings preview.
   - **Active Trip Screen**: Turn-by-turn navigation mockup, customer contact, and **Start Trip OTP entry dialog**.
   - **Earnings Ledger**: Today's earnings, weekly payouts, completed trip breakdowns.

---

## Why Both Appeared Same Previously & The Resolution
1. **Root Cause**: When a phone number was first registered as a Customer, the SQLite record stored `role = 'CUSTOMER'`. Upon re-login under "Driver Partner", the backend previously preserved the existing record's role and did not switch roles, returning a Customer JWT which navigated to `/home`.
2. **Backend Fix**:
   - Updated `/auth/verify-otp` to accept `role: "DRIVER" | "CUSTOMER"` and actively update existing user records to the selected persona.
   - Added `/auth/switch-role` endpoint to enable on-the-fly toggling without logging out.
   - Automatically provisions `DriverProfile` or `CustomerProfile` + `Wallet` on demand.
3. **Frontend Fix**:
   - Added a direct **Driver Partner Mode** switcher button to the Customer Home Screen top header and profile menu.
   - Added a **Customer App** switcher button to the Driver Dashboard top bar.
   - Fixed `OtpVerificationScreen` navigation logic to route directly to `/driver/dashboard` whenever Driver Partner is selected.
