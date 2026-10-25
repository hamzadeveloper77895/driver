import logging
from sqlalchemy import select
from app.core.database import AsyncSessionLocal
from app.models.entities import User, CustomerProfile, DriverProfile, Vehicle, PricingRule, Wallet

logger = logging.getLogger(__name__)


async def seed_database():
    async with AsyncSessionLocal() as db:
        # Check if pricing rules exist
        p_res = await db.execute(select(PricingRule))
        if not p_res.scalars().first():
            logger.info("Seeding pricing rules...")
            db.add_all([
                PricingRule(
                    city="DefaultCity",
                    service_type="HOURLY_LOCAL",
                    base_hours=2.0,
                    base_fare=25.00,
                    extra_minute_rate=0.20,
                    night_charge_start_hour=22,
                    night_charge_end_hour=6,
                    night_charge_flat=5.00,
                    surge_multiplier=1.00
                ),
                PricingRule(
                    city="DefaultCity",
                    service_type="OUTSTATION_ROUND_TRIP",
                    base_hours=8.0,
                    base_fare=75.00,
                    extra_minute_rate=0.15,
                    night_charge_start_hour=22,
                    night_charge_end_hour=6,
                    night_charge_flat=10.00,
                    surge_multiplier=1.00
                )
            ])
            await db.commit()

        # Check if sample driver exists
        d_res = await db.execute(select(User).where(User.phone == "+919876543201"))
        if not d_res.scalars().first():
            logger.info("Seeding demo driver Vikram Singh...")
            driver_user = User(
                phone="+919876543201",
                full_name="Vikram Singh (Senior Chauffeur)",
                role="DRIVER",
                is_active=True
            )
            db.add(driver_user)
            await db.flush()

            driver_profile = DriverProfile(
                user_id=driver_user.id,
                license_number="DL-01-2019-1234",
                experience_years=6,
                rating_average=4.95,
                total_trips=482,
                can_drive_manual=True,
                can_drive_automatic=True,
                duty_status="ONLINE",
                current_lat=12.9716,
                current_lng=77.5946
            )
            db.add(driver_profile)

            # Driver 2
            driver_user2 = User(
                phone="+919876543202",
                full_name="Arjun Nair (Executive Driver)",
                role="DRIVER",
                is_active=True
            )
            db.add(driver_user2)
            await db.flush()

            driver_profile2 = DriverProfile(
                user_id=driver_user2.id,
                license_number="DL-02-2020-5678",
                experience_years=4,
                rating_average=4.88,
                total_trips=295,
                can_drive_manual=True,
                can_drive_automatic=True,
                duty_status="ONLINE",
                current_lat=12.9750,
                current_lng=77.5980
            )
            db.add(driver_profile2)
            await db.commit()

        # Check if demo customer exists
        c_res = await db.execute(select(User).where(User.phone == "+919876543210"))
        if not c_res.scalars().first():
            logger.info("Seeding demo customer Rahul Sharma...")
            customer_user = User(
                phone="+919876543210",
                full_name="Rahul Sharma",
                email="rahul.sharma@example.com",
                role="CUSTOMER",
                is_active=True
            )
            db.add(customer_user)
            await db.flush()

            cp = CustomerProfile(user_id=customer_user.id)
            db.add(cp)
            wallet = Wallet(user_id=customer_user.id, balance=150.00)
            db.add(wallet)

            # Add demo vehicles
            v1 = Vehicle(
                customer_id=customer_user.id,
                brand="Honda",
                model="City ZX",
                year=2022,
                transmission="AUTOMATIC",
                fuel_type="PETROL",
                plate_number="KA01AB1234",
                color="Pearl White",
                is_default=True
            )
            v2 = Vehicle(
                customer_id=customer_user.id,
                brand="Hyundai",
                model="Creta SX",
                year=2023,
                transmission="MANUAL",
                fuel_type="DIESEL",
                plate_number="KA05CD5678",
                color="Phantom Black",
                is_default=False
            )
            db.add_all([v1, v2])
            await db.commit()

        # Check if Admin user exists
        a_res = await db.execute(select(User).where(User.phone == "+919999999999"))
        if not a_res.scalars().first():
            logger.info("Seeding system admin...")
            admin_user = User(
                phone="+919999999999",
                full_name="System Administrator",
                email="admin@chauffeurx.internal",
                role="ADMIN",
                is_active=True
            )
            db.add(admin_user)
            await db.commit()
            logger.info("Database seed completed successfully.")
