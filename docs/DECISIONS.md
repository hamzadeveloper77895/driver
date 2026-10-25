# Architectural Decisions Log (DECISIONS.md)

## DEC-001: Target Identification and Platform
- **Date**: 2026-10-24
- **Context**: The target artifact is `driveu-12-39-0.apk` located in the root workspace (`/Users/test/Desktop/project rea`).
- **Decision**: Analyzed using REA MCP tools (`open_binary`, `identify_flutter_build`, `inspect_artifact`, and `inspect_analysis_view`). Identified that the original app is a native Android application (`com.humblemobile.consumer`, compileSdkVersion 36, targetSdkVersion 35, minSdkVersion 26, using multi-dex and Android Jetpack/Kotlin Clean Architecture). Flutter detection confirmed no Flutter AOT runtime is present.
- **Original App Rebuild**: Rebuilding an original on-demand driver booking / chauffeur service called **"ChauffeurX"** (or **"RideMaster"**), with FastAPI backend and Flutter cross-platform mobile client. Clean-room implementation with 100% original code, models, branding, and assets.

## DEC-002: Backend Architecture & Tech Stack
- **Date**: 2026-10-24
- **Decision**: FastAPI (Python 3.12), SQLAlchemy 2 (async), Alembic migrations, Pydantic v2, PostgreSQL, Redis (pub/sub & geospatial dispatch), Docker Compose.
- **Docker & Local Environment**: Dockerfile and `docker-compose.yml` are provided for standard containerized deployment. Because the host system environment does not have a local Docker daemon installed, the backend is architected with dual runtime adapters: async PostgreSQL + Redis for production/Docker Compose, and async SQLite (`sqlite+aiosqlite`) + in-memory Redis simulator (`fakeredis` / async memory pubsub) for seamless zero-dependency local running, testing, and CI verification.
- **Security & Privacy**: Zero hardcoded third-party API keys, tokens, or original URLs. Clean OpenAPI 3.1 specification designed for the original app.

## DEC-003: Frontend Architecture & Tech Stack
- **Date**: 2026-10-24
- **Decision**: Flutter (Dart 3.x), Riverpod state management, `go_router` navigation, Dio networking with interceptors for token refresh, Material 3 design system, feature-first structure (`core/`, `features/<name>/data, domain, presentation`).

## DEC-004: Dual Repositories and Offline Mock Fallback
- **Date**: 2026-10-24
- **Decision**: Implemented dual repository implementations (`BookingRepositoryImpl` + `MockBookingRepository`, `GarageRepositoryImpl` + `MockGarageRepository`, etc.) controlled by `ApiConstants.useMockData`. This allows full end-to-end execution, widget testing, and demonstrations in environments where the backend dev server is not running or network is offline.

## DEC-005: Customer and Driver Screen Unification
- **Date**: 2026-10-24
- **Decision**: Both Customer and Driver roles are supported within the unified application. Users can switch roles seamlessly during phone authentication (`Customer App` vs `Driver Partner`) or through the navigation drawer, enabling full manual or automated testing of the two-sided marketplace on a single device or simulator.
