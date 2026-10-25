import pytest
import pytest_asyncio
import asyncio
from typing import AsyncGenerator
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from app.main import app
from app.core.database import Base, get_db
from app.core.security import create_access_token
from app.models.entities import User, CustomerProfile, DriverProfile, Vehicle, PricingRule, Wallet

TEST_DATABASE_URL = "sqlite+aiosqlite:///./test_chauffeurx.db"

test_engine = create_async_engine(TEST_DATABASE_URL, echo=False, future=True)
TestingSessionLocal = async_sessionmaker(
    bind=test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False
)


@pytest_asyncio.fixture(autouse=True)
async def setup_db():
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    
    # Seed initial test data
    async with TestingSessionLocal() as session:
        # Pricing Rule
        rule = PricingRule(
            city="DefaultCity",
            service_type="HOURLY_LOCAL",
            base_hours=2.0,
            base_fare=25.00,
            extra_minute_rate=0.20,
            night_charge_start_hour=22,
            night_charge_end_hour=6,
            night_charge_flat=5.00,
            surge_multiplier=1.00
        )
        session.add(rule)

        # Customer
        customer = User(
            id="cust-1234-5678-9012",
            phone="+919876543210",
            full_name="Test Customer",
            role="CUSTOMER",
            is_active=True
        )
        session.add(customer)
        await session.flush()

        cp = CustomerProfile(user_id=customer.id)
        session.add(cp)
        wallet = Wallet(user_id=customer.id, balance=100.00)
        session.add(wallet)

        # Vehicles: one automatic, one manual
        v_auto = Vehicle(
            id="veh-auto-1234",
            customer_id=customer.id,
            brand="Honda",
            model="City",
            transmission="AUTOMATIC",
            plate_number="KA01AA1111",
            is_default=True
        )
        v_manual = Vehicle(
            id="veh-manu-5678",
            customer_id=customer.id,
            brand="Hyundai",
            model="i20",
            transmission="MANUAL",
            plate_number="KA02BB2222",
            is_default=False
        )
        session.add_all([v_auto, v_manual])

        # Driver
        driver = User(
            id="driv-1234-5678-9012",
            phone="+919876543201",
            full_name="Vikram Singh",
            role="DRIVER",
            is_active=True
        )
        session.add(driver)
        await session.flush()

        dp = DriverProfile(
            user_id=driver.id,
            license_number="DL-TEST-9999",
            can_drive_manual=True,
            can_drive_automatic=True,
            duty_status="ONLINE",
            current_lat=12.9716,
            current_lng=77.5946
        )
        session.add(dp)
        await session.commit()

    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


async def override_get_db() -> AsyncGenerator[AsyncSession, None]:
    async with TestingSessionLocal() as session:
        yield session


app.dependency_overrides[get_db] = override_get_db


@pytest_asyncio.fixture
async def client() -> AsyncGenerator[AsyncClient, None]:
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.fixture
def customer_auth_headers():
    token = create_access_token({"sub": "cust-1234-5678-9012", "phone": "+919876543210", "role": "CUSTOMER"})
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def driver_auth_headers():
    token = create_access_token({"sub": "driv-1234-5678-9012", "phone": "+919876543201", "role": "DRIVER"})
    return {"Authorization": f"Bearer {token}"}
