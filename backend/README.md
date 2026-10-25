# ChauffeurX Backend API

High-performance on-demand chauffeur and personal driver platform backend built with FastAPI, SQLAlchemy 2 (async), PostgreSQL, and Redis.

## Tech Stack
- **API Framework**: FastAPI 0.110+ (Python 3.12 / 3.9+)
- **ORM & Migrations**: SQLAlchemy 2.0 (async), Alembic
- **Databases**: PostgreSQL 16 (production) / SQLite `aiosqlite` (local standalone)
- **Cache & Realtime**: Redis 7 (GEO spatial index, pub/sub) / FakeRedis (fallback)
- **Containers**: Docker, Docker Compose

## Quick Start

### Option A: Running with Docker Compose (Recommended)
```bash
docker compose up --build
```
API docs available at: `http://localhost:8000/docs`

### Option B: Running Standalone Locally
```bash
# 1. Activate virtual environment
source .venv/bin/activate

# 2. Run backend server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Running Test Suite
```bash
pytest -v tests
```

### Running Autonomous Driver Simulator
```bash
# Simulates a complete trip lifecycle (Accept -> On Way -> Arrive -> OTP Verify -> Drive -> Complete)
python -m app.simulator <booking_id>
```
