import json
from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from app.core.database import get_db
from app.core.redis import get_redis
from app.models.entities import User, DriverProfile, Booking, TripTelemetry, Wallet, WalletTransaction
from app.schemas.schemas import DutyStatusUpdate, DriverTelemetryCreate, StartTripRequest, BookingOut
from app.api.deps import get_current_user, require_role
from app.api.v1.bookings import build_booking_response
from app.services.state_machine import BookingStateMachine
from app.services.dispatch_service import DispatchService
from app.services.websocket_manager import ws_manager

router = APIRouter(prefix="/driver", tags=["Driver Operations"])


@router.put("/duty-status")
async def update_duty_status(
    payload: DutyStatusUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(DriverProfile).where(DriverProfile.user_id == current_user.id))
    driver_prof = result.scalars().first()
    if not driver_prof:
        raise HTTPException(status_code=404, detail="Driver profile not found")

    status_clean = payload.duty_status.upper().strip()
    if status_clean not in ["ONLINE", "OFFLINE"]:
        raise HTTPException(status_code=400, detail="Status must be ONLINE or OFFLINE")

    driver_prof.duty_status = status_clean
    driver_prof.last_heartbeat = datetime.now(timezone.utc)
    await db.commit()

    if status_clean == "OFFLINE":
        await DispatchService.remove_driver_from_pool(current_user.id)

    return {"duty_status": status_clean, "driver_id": current_user.id}


@router.post("/telemetry")
async def update_telemetry(
    payload: DriverTelemetryCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(DriverProfile).where(DriverProfile.user_id == current_user.id))
    driver_prof = result.scalars().first()
    if not driver_prof:
        raise HTTPException(status_code=404, detail="Driver profile not found")

    driver_prof.current_lat = payload.latitude
    driver_prof.current_lng = payload.longitude
    driver_prof.last_heartbeat = datetime.now(timezone.utc)
    await db.commit()

    # Update in Redis GEO if online
    if driver_prof.duty_status == "ONLINE":
        await DispatchService.update_driver_location(current_user.id, payload.latitude, payload.longitude)

    # Check if driver is on an active trip and broadcast live update
    active_b = await db.execute(
        select(Booking).where(
            Booking.driver_id == current_user.id,
            Booking.status.in_(["DRIVER_ASSIGNED", "ON_WAY", "ARRIVED", "IN_PROGRESS"])
        )
    )
    booking = active_b.scalars().first()
    if booking:
        # Save telemetry point
        telemetry = TripTelemetry(
            booking_id=booking.id,
            driver_id=current_user.id,
            latitude=payload.latitude,
            longitude=payload.longitude,
            bearing=payload.bearing,
            speed=payload.speed
        )
        db.add(telemetry)
        await db.commit()

        # Broadcast event
        await ws_manager.broadcast_to_trip(booking.id, "DRIVER_LOCATION_UPDATE", {
            "booking_id": booking.id,
            "latitude": payload.latitude,
            "longitude": payload.longitude,
            "bearing": payload.bearing,
            "speed": payload.speed
        })

    return {"recorded": True}


@router.get("/offers")
async def get_pending_offer(current_user: User = Depends(get_current_user)):
    redis = await get_redis()
    offer_raw = await redis.get(f"driver:pending_offer:{current_user.id}")
    if not offer_raw:
        return {"offer": None}
    return {"offer": json.loads(offer_raw)}


@router.post("/offers/{booking_id}/respond", response_model=BookingOut)
async def respond_to_offer(
    booking_id: str,
    accept: bool = True,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    query = (
        select(Booking)
        .options(
            selectinload(Booking.vehicle),
            selectinload(Booking.driver).selectinload(User.driver_profile)
        )
        .where(Booking.id == booking_id)
    )
    result = await db.execute(query)
    booking = result.scalars().first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    redis = await get_redis()
    await redis.delete(f"driver:pending_offer:{current_user.id}")

    if not accept:
        return build_booking_response(booking)

    # Acquire distributed lock
    lock_key = f"lock:booking:{booking_id}"
    acquired = await redis.set(lock_key, current_user.id, nx=True, ex=10)
    if not acquired:
        raise HTTPException(status_code=409, detail="Offer already accepted by another driver")

    try:
        BookingStateMachine.transition(
            booking=booking,
            target_status="DRIVER_ASSIGNED",
            actor_role="DRIVER",
            driver_id=current_user.id
        )
        await db.commit()
        await db.refresh(booking, ["driver", "vehicle"])
        # Eagerly load driver_profile
        if booking.driver:
            await db.refresh(booking.driver, ["driver_profile"])
    finally:
        await redis.delete(lock_key)

    # Broadcast acceptance to customer
    await ws_manager.broadcast_to_trip(booking.id, "DRIVER_ASSIGNED", {
        "booking_id": booking.id,
        "driver_id": current_user.id,
        "driver_name": current_user.full_name,
        "start_otp": booking.start_otp,
        "status": booking.status
    })

    return build_booking_response(booking)


@router.post("/trips/{booking_id}/arrive", response_model=BookingOut)
async def mark_driver_arrived(
    booking_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    query = (
        select(Booking)
        .options(
            selectinload(Booking.vehicle),
            selectinload(Booking.driver).selectinload(User.driver_profile)
        )
        .where(Booking.id == booking_id, Booking.driver_id == current_user.id)
    )
    result = await db.execute(query)
    booking = result.scalars().first()
    if not booking:
        raise HTTPException(status_code=404, detail="Active booking not found")

    BookingStateMachine.transition(
        booking=booking,
        target_status="ARRIVED",
        actor_role="DRIVER"
    )
    await db.commit()
    await db.refresh(booking)

    await ws_manager.broadcast_to_trip(booking.id, "DRIVER_ARRIVED", {
        "booking_id": booking.id,
        "status": "ARRIVED",
        "message": "Driver has arrived at the pickup location"
    })

    return build_booking_response(booking)


@router.post("/trips/{booking_id}/start", response_model=BookingOut)
async def start_trip(
    booking_id: str,
    payload: StartTripRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    query = (
        select(Booking)
        .options(
            selectinload(Booking.vehicle),
            selectinload(Booking.driver).selectinload(User.driver_profile)
        )
        .where(Booking.id == booking_id, Booking.driver_id == current_user.id)
    )
    result = await db.execute(query)
    booking = result.scalars().first()
    if not booking:
        raise HTTPException(status_code=404, detail="Active booking not found")

    BookingStateMachine.transition(
        booking=booking,
        target_status="IN_PROGRESS",
        actor_role="DRIVER",
        otp=payload.otp
    )
    await db.commit()
    await db.refresh(booking)

    await ws_manager.broadcast_to_trip(booking.id, "TRIP_STARTED", {
        "booking_id": booking.id,
        "status": "IN_PROGRESS",
        "trip_start_time": booking.trip_start_time.isoformat()
    })

    return build_booking_response(booking)


@router.post("/trips/{booking_id}/complete", response_model=BookingOut)
async def complete_trip(
    booking_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    query = (
        select(Booking)
        .options(
            selectinload(Booking.vehicle),
            selectinload(Booking.driver).selectinload(User.driver_profile)
        )
        .where(Booking.id == booking_id, Booking.driver_id == current_user.id)
    )
    result = await db.execute(query)
    booking = result.scalars().first()
    if not booking:
        raise HTTPException(status_code=404, detail="Active booking not found")

    BookingStateMachine.transition(
        booking=booking,
        target_status="COMPLETED",
        actor_role="DRIVER"
    )

    # Process payment if WALLET
    if booking.payment_mode == "WALLET":
        w_res = await db.execute(select(Wallet).where(Wallet.user_id == booking.customer_id))
        wallet = w_res.scalars().first()
        if wallet and wallet.balance >= booking.final_fare:
            wallet.balance -= booking.final_fare
            booking.payment_status = "PAID"
            tx = WalletTransaction(
                wallet_id=wallet.id,
                booking_id=booking.id,
                amount=-booking.final_fare,
                transaction_type="DEBIT",
                description=f"Trip Payment for {booking.booking_code}"
            )
            db.add(tx)

    # Update driver stats
    d_res = await db.execute(select(DriverProfile).where(DriverProfile.user_id == current_user.id))
    driver_prof = d_res.scalars().first()
    if driver_prof:
        driver_prof.total_trips += 1
        driver_prof.duty_status = "ONLINE"

    await db.commit()
    await db.refresh(booking)

    await ws_manager.broadcast_to_trip(booking.id, "TRIP_COMPLETED", {
        "booking_id": booking.id,
        "status": "COMPLETED",
        "final_fare": booking.final_fare,
        "payment_mode": booking.payment_mode,
        "payment_status": booking.payment_status
    })

    return build_booking_response(booking)


@router.get("/earnings")
async def get_driver_earnings(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(Booking).where(Booking.driver_id == current_user.id, Booking.status == "COMPLETED")
    )
    trips = result.scalars().all()
    total_earnings = sum((b.final_fare or 0.0) * 0.80 for b in trips)  # 80% payout

    return {
        "trips_completed": len(trips),
        "total_earnings": round(total_earnings, 2),
        "currency": "USD"
    }
