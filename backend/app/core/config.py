from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "ChauffeurX"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = "development"
    
    # Security
    SECRET_KEY: str = "chauffeurx_super_secret_jwt_key_2026_change_in_production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 1 day for dev ease, 15 min in prod
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    
    # Database
    DATABASE_URL: str = "sqlite+aiosqlite:///./chauffeurx.db"
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"
    USE_FAKE_REDIS_FALLBACK: bool = True
    
    # Dispatch & Surcharges
    DISPATCH_TIMEOUT_SECONDS: int = 60
    INITIAL_RADIUS_KM: float = 3.0
    MAX_RADIUS_KM: float = 10.0
    NIGHT_SURCHARGE_START: int = 22
    NIGHT_SURCHARGE_END: int = 6
    NIGHT_SURCHARGE_FLAT: float = 5.00
    TAX_RATE: float = 0.18
    
    # CORS
    BACKEND_CORS_ORIGINS: List[str] = ["*"]

    model_config = SettingsConfigDict(
        env_file=".env",
        case_sensitive=True,
        extra="allow"
    )


settings = Settings()
