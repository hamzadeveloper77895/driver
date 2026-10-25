import asyncio
import logging
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from app.core.database import AsyncSessionLocal
from app.models.entities import User, Booking, DriverProfile
from app.services.state_machine import BookingStateMachine
from app.services.websocket_manager import ws_manager

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("DriverSimulator")


async def simulate_booking_lifecycle(booking_id: str, speed_multiplier: float = 1.0, session_factory=None):
    """
    Executes an autonomous full-lifecycle chauffeur booking simulation:
    Pending -> Driver Assigned -> On Way -> Arrived -> In Progress (with OTP) -> Completed.
    """
    logger.info("==================================================")
    logger.info("STARTING DRIVER SIMULATION FOR BOOKING: %s", booking_id)
    logger.info("==================================================")

    step_delay = 1.0 / speed_multiplier
    factory = session_factory or AsyncSessionLocal

    async with factory() as db:
        query = (
            select(Booking)
            .options(
                selectinload(Booking.customer),
                selectinload(Booking.vehicle)
            )
            .where(Booking.id == booking_id)
        )
        result = await db.execute(query)
        booking = result.scalars().first()
        if not booking:
            logger.error("Booking %s not found!", booking_id)
            return False

        # Find or select seeded driver
        d_res = await db.execute(
            select(User)
            .options(selectinload(User.driver_profile))
            .where(User.phone == "+919876543201")
        )
        driver = d_res.scalars().first()
        if not driver:
            logger.error("Seeded driver Vikram Singh not found.")
            return False

        # STEP 1: Driver Accepts Offer -> DRIVER_ASSIGNED
        logger.info("[STEP 1/5] Driver %s accepting booking offer...", driver.full_name)
        BookingStateMachine.transition(
            booking=booking,
            target_status="DRIVER_ASSIGNED",
            actor_role="DRIVER",
            driver_id=driver.id
        )
        await db.commit()
        await ws_manager.broadcast_to_trip(booking.id, "DRIVER_ASSIGNED", {
            "booking_id": booking.id,
            "driver_name": driver.full_name,
            "start_otp": booking.start_otp,
            "status": booking.status
        })
        logger.info("  -> Status: DRIVER_ASSIGNED | Start OTP Generated: %s", booking.start_otp)
        await asyncio.sleep(step_delay)

        # STEP 2: Driver En Route -> ON_WAY
        logger.info("[STEP 2/5] Driver starting navigation towards pickup location...")
        BookingStateMachine.transition(
            booking=booking,
            target_status="ON_WAY",
            actor_role="DRIVER"
        )
        await db.commit()
        await ws_manager.broadcast_to_trip(booking.id, "DRIVER_LOCATION_UPDATE", {
            "booking_id": booking.id,
            "latitude": booking.pickup_lat - 0.005,
            "longitude": booking.pickup_lng - 0.005,
            "status": "ON_WAY",
            "eta_minutes": 5
        })
        logger.info("  -> Status: ON_WAY | Telemetry streaming active")
        await asyncio.sleep(step_delay)

        # STEP 3: Driver Arrives at Pickup -> ARRIVED
        logger.info("[STEP 3/5] Driver arrived at pickup location (%s)...", booking.pickup_address)
        BookingStateMachine.transition(
            booking=booking,
            target_status="ARRIVED",
            actor_role="DRIVER"
        )
        await db.commit()
        await ws_manager.broadcast_to_trip(booking.id, "DRIVER_ARRIVED", {
            "booking_id": booking.id,
            "status": "ARRIVED",
            "message": "Chauffeur has arrived at your vehicle"
        })
        logger.info("  -> Status: ARRIVED | Awaiting customer Start-Trip OTP")
        await asyncio.sleep(step_delay)

        # STEP 4: Start Trip with OTP -> IN_PROGRESS
        otp_to_use = booking.start_otp
        logger.info("[STEP 4/5] Driver entering customer Start OTP: %s...", otp_to_use)
        BookingStateMachine.transition(
            booking=booking,
            target_status="IN_PROGRESS",
            actor_role="DRIVER",
            otp=otp_to_use
        )
        await db.commit()
        await ws_manager.broadcast_to_trip(booking.id, "TRIP_STARTED", {
            "booking_id": booking.id,
            "status": "IN_PROGRESS",
            "trip_start_time": booking.trip_start_time.isoformat()
        })
        logger.info("  -> Status: IN_PROGRESS | Metering running, vehicle en route")
        await asyncio.sleep(step_delay * 1.5)

        # STEP 5: Destination Reached -> COMPLETED
        logger.info("[STEP 5/5] Reached destination. Chauffeur ending trip and finalizing fare...")
        BookingStateMachine.transition(
            booking=booking,
            target_status="COMPLETED",
            actor_role="DRIVER"
        )
        booking.payment_status = "PAID"
        await db.commit()
        await ws_manager.broadcast_to_trip(booking.id, "TRIP_COMPLETED", {
            "booking_id": booking.id,
            "status": "COMPLETED",
            "final_fare": booking.final_fare,
            "payment_status": "PAID"
        })
        logger.info("  -> Status: COMPLETED | Final Fare: $%s | Payment: %s", booking.final_fare, booking.payment_status)
        logger.info("==================================================")
        logger.info("SIMULATION COMPLETED SUCCESSFULLY!")
        logger.info("==================================================")
        return True


if __name__ == "__main__":
    import sys
    b_id = sys.argv[1] if len(sys.argv) > 1 else None
    if not b_id:
        print("Usage: python -m app.simulator <booking_id>")
    else:
        asyncio.run(simulate_booking_lifecycle(b_id))
