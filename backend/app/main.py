from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.database import engine, Base
import app.models.entities  # noqa: F401
from app.core.redis import close_redis
from app.api.v1.health import router as health_router
from app.api.v1.auth import router as auth_router
from app.api.v1.garage import router as garage_router
from app.api.v1.pricing import router as pricing_router
from app.api.v1.bookings import router as bookings_router
from app.api.v1.driver import router as driver_router
from app.api.v1.wallet import router as wallet_router
from app.api.v1.websockets import router as ws_router
from app.api.v1.admin import router as admin_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: ensure tables exist
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    # Run database seed
    from app.seeds import seed_database
    await seed_database()
    
    yield
    # Shutdown
    await close_redis()
    await engine.dispose()


app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="High-performance backend API for on-demand personal chauffeur and driver dispatch platform.",
    lifespan=lifespan
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(health_router, prefix=settings.API_V1_STR)
app.include_router(auth_router, prefix=settings.API_V1_STR)
app.include_router(garage_router, prefix=settings.API_V1_STR)
app.include_router(pricing_router, prefix=settings.API_V1_STR)
app.include_router(bookings_router, prefix=settings.API_V1_STR)
app.include_router(driver_router, prefix=settings.API_V1_STR)
app.include_router(wallet_router, prefix=settings.API_V1_STR)
app.include_router(admin_router, prefix=settings.API_V1_STR)
app.include_router(admin_router)
app.include_router(ws_router)


@app.get("/")
async def root():
    return {
        "app": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "docs": "/docs",
        "openapi": "/openapi.json"
    }
