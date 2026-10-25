# System Runbook & Operations Guide (RUNBOOK.md)

This runbook describes operational procedures, container lifecycle, configuration variables, troubleshooting, and verification steps for ChauffeurX.

---

## 1. Environment Configurations

| Environment Variable | Description | Default |
| :--- | :--- | :--- |
| `DATABASE_URL` | Async SQLAlchemy database connection string | `sqlite+aiosqlite:///./chauffeurx.db` |
| `REDIS_URL` | Redis connection URL | `redis://localhost:6379/0` |
| `SECRET_KEY` | HMAC SHA-256 secret key for signing JWTs | `chauffeurx_super_secret_jwt_key_2026_change_in_production` |
| `ENVIRONMENT` | Deployment environment (`development`, `production`, `test`) | `development` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Access token lifespan in minutes | `1440` (24h) |
| `DISPATCH_TIMEOUT_SECONDS` | Driver acceptance window before radius escalation | `60` |

---

## 2. Launching Services

### 2.1 Production Deployment (Docker Compose)
```bash
cd backend
docker compose up -d
docker compose logs -f api
```

### 2.2 Local Development (No Docker Required)
The application automatically starts with zero dependencies by utilizing `aiosqlite` and `fakeredis`:
```bash
cd backend
source .venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

---

## 3. Autonomous Verification & Testing

### 3.1 Execute Pytest Test Suite
Runs all 25 unit and integration tests:
```bash
cd backend
.venv/bin/pytest -v tests
```

### 3.2 Testing the Driver Simulator
To observe an autonomous simulated chauffeur completing a booking:
```bash
# 1. Create a booking via API or use seeded booking
curl -X POST http://localhost:8000/api/v1/bookings \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "vehicle_id": "<VEHICLE_ID>",
    "service_type": "HOURLY_LOCAL",
    "duration_hours": 2.0,
    "pickup_address": "MG Road, Bengaluru",
    "pickup_lat": 12.9716,
    "pickup_lng": 77.5946
  }'

# 2. Run simulation on returned booking ID
.venv/bin/python -m app.simulator <BOOKING_ID>
```

---

## 4. Troubleshooting & Health Checks
- **Health Check Endpoint**: `GET http://localhost:8000/api/v1/health`
- **Database Locks**: If a database lock occurs in SQLite during high-concurrency testing, ensure WAL mode is active: `PRAGMA journal_mode=WAL;`.
- **Redis Connection Failures**: If Redis is unreachable, the system automatically falls back to in-memory `FakeRedis` without throwing unhandled exceptions.
