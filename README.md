# driver - ChauffeurX On-Demand Personal Chauffeur Platform

Clean-room engineered, on-demand personal chauffeur mobility platform. Customers hire background-verified drivers to drive their personal cars, while driver partners manage duty, accept ride requests, navigate trips with Start-Trip OTP verification, and track real-time earnings.

---

## Architecture Overview

```
project-rea/
├── backend/          # FastAPI async backend (Python 3.12, SQLAlchemy 2, Redis GEO, WebSockets)
├── mobile/           # Flutter cross-platform client (Riverpod 2, GoRouter, Material 3 Dark Midnight)
├── openapi/          # Formal OpenAPI 3.1 specification (openapi.yaml)
└── docs/             # Reverse-engineered specifications, state machine, RBAC & production roadmaps
```

### 1. Backend (`/backend`)
- **FastAPI Framework**: High-performance asynchronous REST API.
- **Dual Database Adapters**: SQLite (`aiosqlite`) for zero-dependency local runs; PostgreSQL with Alembic for cloud production.
- **Dual Redis Caching**: `fakeredis` fallback with full Redis GEO and Pub/Sub trip dispatch.
- **Interactive Admin Portal**: Built-in operations dashboard at `/admin` to inspect trips, configure fare rules, and verify drivers.
- **Autonomous Driver Simulator**: Realistic physics and waypoint broadcaster for testing without live drivers.

### 2. Mobile App (`/mobile`)
- **Dual Persona Flows**:
  - **Customer App**: Hourly & outstation bookings, personal garage management, dynamic fare breakdown, start-trip OTP code, interactive live tracking map, and digital wallet.
  - **Driver Partner App**: Duty status toggle (`ONLINE` / `OFFLINE`), incoming offer radar with countdown timer, turn-by-turn navigation mockup, Start-Trip OTP verification dialog, and daily/weekly earnings ledger.
- **Clean Architecture**: Feature-first repository pattern with mock and real HTTP/WebSocket API adapters.
- **Midnight Dark Theme**: Custom neon purple (`#6C5CE7`) and cyber cyan (`#00CEC9`) tokens on deep navy background (`#0B132B`).

### 3. Documentation (`/docs`)
- `02_ROLES.md`: Role-Based Access Control matrix (Customer, Driver, Admin).
- `05_FEATURES.md`: Transmission matching, dynamic fare math, and OTP security.
- `06_STATE_MACHINE.md`: Mathematical booking state machine with illegal skip guards.
- `07_DATA_MODELS.md`: Complete database ER schemas and entities.
- `ROLE_WORKFLOWS.md`: Detailed comparison and routing guide for Customer vs Driver Partner flows.
- `PRODUCTION_ROADMAP.md`: Step-by-step instructions for connecting Stripe, Twilio, Google Maps, and FCM.

---

## Quick Start Guide

### 1. Run the Backend
```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```
- API Documentation: [http://localhost:8000/docs](http://localhost:8000/docs)
- Admin Portal: [http://localhost:8000/admin](http://localhost:8000/admin)

### 2. Run the Mobile App
```bash
cd mobile
flutter pub get
flutter run
```

### 3. Run Backend & Frontend Tests
```bash
# Backend pytest suite (25/25 passing)
cd backend && pytest -v tests

# Flutter widget & unit test suite (7/7 passing)
cd mobile && flutter test
```
