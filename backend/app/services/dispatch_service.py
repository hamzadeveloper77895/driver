import json
import logging
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.redis import get_redis
from app.models.entities import DriverProfile, User, Booking, Vehicle

logger = logging.getLogger(__name__)


class DispatchService:
    @staticmethod
    async def update_driver_location(driver_id: str, latitude: float, longitude: float) -> None:
        redis = await get_redis()
        # Add to Redis GEO index
        try:
            await redis.geoadd("drivers:available", (longitude, latitude, driver_id))
        except Exception:
            # FakeRedis or alternative syntax support
            try:
                await redis.geoadd("drivers:available", longitude, latitude, driver_id)
            except Exception as e:
                logger.warning("geoadd failed: %s", e)
        # Store individual coordinates key
        await redis.set(f"driver:loc:{driver_id}", json.dumps({"lat": latitude, "lng": longitude}), ex=120)

    @staticmethod
    async def remove_driver_from_pool(driver_id: str) -> None:
        redis = await get_redis()
        try:
            await redis.zrem("drivers:available", driver_id)
        except Exception:
            pass
        await redis.delete(f"driver:loc:{driver_id}")

    @classmethod
    async def find_eligible_drivers(
        cls,
        session: AsyncSession,
        pickup_lat: float,
        pickup_lng: float,
        transmission_required: str,
        radius_km: float = 10.0
    ) -> List[DriverProfile]:
        """Finds online drivers matching the required car transmission type."""
        query = (
            select(DriverProfile)
            .join(User, DriverProfile.user_id == User.id)
            .where(DriverProfile.duty_status == "ONLINE")
            .where(User.is_active == True)
        )
        if transmission_required.upper() == "MANUAL":
            query = query.where(DriverProfile.can_drive_manual == True)
        elif transmission_required.upper() == "AUTOMATIC":
            query = query.where(DriverProfile.can_drive_automatic == True)

        result = await session.execute(query)
        drivers = list(result.scalars().all())

        # If driver has location, sort by distance; otherwise include all online drivers
        def distance_key(d: DriverProfile):
            if d.current_lat is not None and d.current_lng is not None:
                from app.services.pricing_service import PricingService
                return PricingService.calculate_distance(pickup_lat, pickup_lng, d.current_lat, d.current_lng)
            return 999.0

        drivers.sort(key=distance_key)
        return drivers

    @classmethod
    async def broadcast_dispatch_offer(
        cls,
        booking: Booking,
        vehicle: Vehicle,
        driver_id: str
    ) -> None:
        redis = await get_redis()
        offer_payload = {
            "event": "DISPATCH_OFFER",
            "data": {
                "booking_id": booking.id,
                "booking_code": booking.booking_code,
                "service_type": booking.service_type,
                "duration_hours": booking.duration_hours,
                "pickup_address": booking.pickup_address,
                "pickup_lat": booking.pickup_lat,
                "pickup_lng": booking.pickup_lng,
                "drop_address": booking.drop_address,
                "car": {
                    "brand": vehicle.brand,
                    "model": vehicle.model,
                    "transmission": vehicle.transmission,
                    "plate_number": vehicle.plate_number
                },
                "estimated_fare": booking.estimated_fare,
                "timeout_seconds": 30
            }
        }
        channel = f"channel:driver:dispatch:{driver_id}"
        await redis.publish(channel, json.dumps(offer_payload))
        # Store pending offer in Redis
        await redis.set(f"driver:pending_offer:{driver_id}", json.dumps(offer_payload["data"]), ex=35)
