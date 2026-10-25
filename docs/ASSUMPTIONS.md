# Assumptions Log (ASSUMPTIONS.md)

## ASM-001: REA Capabilities and Target Analysis Fallbacks
- **Context**: REA MCP tools (`open_binary`, `identify_flutter_build`, `inspect_artifact`) verified the target is `driveu-12-39-0.apk`. `identify_flutter_build` reported `flutter_detected: false`.
- **Finding**: The app is built with native Android multi-dex Kotlin/Java.
- **REA JADX Requirement**: `inspect_android_package` reported that headless JADX jar is not pre-bundled in the REA MCP image (`capability_unavailable`). Full artifact extraction collided on macOS APFS case-insensitivity (`res/-8h.xml` vs `res/-8H.xml`).
- **Assumption / Fallback**: As instructed in PART 1.5 ("If REA cannot extract something, fall back to resources, strings, assets and any recordings, and log it in /docs/ASSUMPTIONS.md"), we correlate REA artifact inspection with decoded `manifest.txt`, APK assets (`supplierconfig.json`, juspay bundles, layouts, string tables), and dex symbol analysis to accurately reconstruct the domain models, screen flows, state machines, and API contracts.

## ASM-002: Domain & Service Paradigm
- **Context**: DriveU / Drive4U provides on-demand chauffeur / private driver services (hiring a professional driver to drive the customer's own car for one-way trips, round trips, outstation, or maintenance).
- **Service Categories**:
  1. **City Drive (Hourly / Local)**: Book a driver per hour (e.g., minimum 2 hrs, 4 hrs, 8 hrs).
  2. **Round Trip / Outstation**: Travel to another city with driver.
  3. **Car Care / Maintenance**: Driver picks up car for service/wash and returns.
- **User Roles**:
  - `CUSTOMER`: Books drivers, manages vehicle profiles, tracks live ride, pays fare.
  - `DRIVER`: Receives dispatch offers, accepts/declines, navigates, updates trip lifecycle, views earnings.
  - `ADMIN`: Manages pricing rules, dispatches, audits trips, views analytics.

## ASM-003: Clean-Room Implementation & App Identity
- **Original App Identity**: Named **"Veloce"** (or **"DriveFlow"** / **"ChauffeurX"**).
- **Color Palette & Design System**: Modern Deep Midnight Slate (`#0F172A`), Electric Indigo (`#6366F1`), Emerald Green (`#10B981`), Amber (`#F59E0B`). High aesthetic quality with glassmorphism, responsive cards, crisp typography (Inter/Roboto), and polished micro-animations.
- **Zero Third-Party Leaks**: All original URLs, backend endpoints, and API contracts are 100% original, documented in `/openapi/openapi.yaml`.
