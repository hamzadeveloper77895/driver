import asyncio
import uuid
import random
from typing import List, Optional
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from app.core.database import get_db
from app.models.entities import User, Booking, Vehicle, PricingRule, DriverRating, Wallet, WalletTransaction
from app.schemas.schemas import BookingCreate, BookingOut, BookingCancelRequest, BookingRateRequest, DriverSummary
from app.api.deps import get_current_user
from app.services.pricing_service import PricingService
from app.services.state_machine import BookingStateMachine
from app.services.dispatch_service import DispatchService
from app.services.websocket_manager import ws_manager

router = APIRouter(prefix="/bookings", tags=["Bookings"])


def build_booking_response(b: Booking) -> BookingOut:
    driver_summary = None
    if b.driver and b.driver.driver_profile:
        dp = b.driver.driver_profile
        driver_summary = DriverSummary(
            id=b.driver.id,
            full_name=b.driver.full_name,
            avatar_url=b.driver.avatar_url,
            phone=b.driver.phone,
            rating_average=dp.rating_average,
            total_trips=dp.total_trips,
            current_lat=dp.current_lat,
            current_lng=dp.current_lng
        )
    return BookingOut(
        id=b.id,
        booking_code=b.booking_code,
        customer_id=b.customer_id,
        driver_id=b.driver_id,
        vehicle_id=b.vehicle_id,
        service_type=b.service_type,
        booking_type=b.booking_type,
        status=b.status,
        pickup_address=b.pickup_address,
        pickup_lat=b.pickup_lat,
        pickup_lng=b.pickup_lng,
        drop_address=b.drop_address,
        drop_lat=b.drop_lat,
        drop_lng=b.drop_lng,
        start_otp=b.start_otp,
        trip_start_time=b.trip_start_time,
        trip_end_time=b.trip_end_time,
        estimated_fare=b.estimated_fare,
        final_fare=b.final_fare,
        payment_mode=b.payment_mode,
        payment_status=b.payment_status,
        emergency_sos_triggered=b.emergency_sos_triggered,
        created_at=b.created_at,
        driver=driver_summary,
        vehicle=b.vehicle
    )


@router.post("", response_model=BookingOut, status_code=status.HTTP_201_CREATED)
async def create_booking(
    payload: BookingCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Verify vehicle ownership
    v_res = await db.execute(
        select(Vehicle).where(Vehicle.id == payload.vehicle_id, Vehicle.customer_id == current_user.id)
    )
    vehicle = v_res.scalars().first()
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found in your garage")

    # Compute fare
    p_res = await db.execute(
        select(PricingRule).where(PricingRule.service_type == payload.service_type, PricingRule.is_active == True)
    )
    rule = p_res.scalars().first()
    quote = PricingService.estimate_fare(
        rule=rule,
        service_type=payload.service_type,
        duration_hours=payload.duration_hours,
        pickup_lat=payload.pickup_lat,
        pickup_lng=payload.pickup_lng,
        drop_lat=payload.drop_lat,
        drop_lng=payload.drop_lng,
        promo_code=payload.promo_code
    )

    code = f"BK-{random.randint(100000, 999999)}"
    booking = Booking(
        booking_code=code,
        customer_id=current_user.id,
        vehicle_id=vehicle.id,
        service_type=payload.service_type,
        booking_type=payload.booking_type,
        scheduled_pickup_time=payload.scheduled_pickup_time,
        duration_hours=payload.duration_hours,
        pickup_address=payload.pickup_address,
        pickup_lat=payload.pickup_lat,
        pickup_lng=payload.pickup_lng,
        drop_address=payload.drop_address,
        drop_lat=payload.drop_lat,
        drop_lng=payload.drop_lng,
        estimated_fare=quote.total_fare,
        payment_mode=payload.payment_mode,
        status="PENDING"
    )
    db.add(booking)
    await db.commit()
    await db.refresh(booking, ["vehicle"])

    # Trigger async dispatch search
    eligible_drivers = await DispatchService.find_eligible_drivers(
        session=db,
        pickup_lat=payload.pickup_lat,
        pickup_lng=payload.pickup_lng,
        transmission_required=vehicle.transmission
    )

    for driver_prof in eligible_drivers[:3]:
        await DispatchService.broadcast_dispatch_offer(booking, vehicle, driver_prof.user_id)

    return build_booking_response(booking)


@router.get("/active", response_model=Optional[BookingOut])
async def get_active_booking(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    query = (
        select(Booking)
        .options(
            selectinload(Booking.vehicle),
            selectinload(Booking.driver).selectinload(User.driver_profile)
        )
        .where(
            Booking.customer_id == current_user.id,
            Booking.status.in_(["PENDING", "DRIVER_ASSIGNED", "ON_WAY", "ARRIVED", "IN_PROGRESS"])
        )
        .order_by(Booking.created_at.desc())
    )
    result = await db.execute(query)
    booking = result.scalars().first()
    if not booking:
        return None
    return build_booking_response(booking)


@router.get("/history", response_model=List[BookingOut])
async def get_booking_history(
    current_user: User = Depends(get_current_user),
    limit: int = Query(20, ge=1, le=50),
    db: AsyncSession = Depends(get_db)
):
    query = (
        select(Booking)
        .options(
            selectinload(Booking.vehicle),
            selectinload(Booking.driver).selectinload(User.driver_profile)
        )
        .where(
            Booking.customer_id == current_user.id,
            Booking.status.in_(["COMPLETED", "CANCELLED", "REJECTED", "DISPUTED"])
        )
        .order_by(Booking.created_at.desc())
        .limit(limit)
    )
    result = await db.execute(query)
    return [build_booking_response(b) for b in result.scalars().all()]


@router.get("/{booking_id}", response_model=BookingOut)
async def get_booking_by_id(
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
        .where(Booking.id == booking_id)
    )
    result = await db.execute(query)
    booking = result.scalars().first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    if current_user.role != "ADMIN" and booking.customer_id != current_user.id and booking.driver_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to access this booking")

    return build_booking_response(booking)


@router.post("/{booking_id}/cancel", response_model=BookingOut)
async def cancel_booking(
    booking_id: str,
    payload: BookingCancelRequest,
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

    BookingStateMachine.transition(
        booking=booking,
        target_status="CANCELLED",
        actor_role=current_user.role,
        reason=payload.reason
    )
    await db.commit()
    await db.refresh(booking)

    # Broadcast event
    await ws_manager.broadcast_to_trip(booking.id, "BOOKING_CANCELLED", {
        "booking_id": booking.id,
        "reason": booking.cancellation_reason,
        "cancellation_fee": booking.cancellation_fee
    })

    return build_booking_response(booking)


@router.post("/{booking_id}/sos")
async def trigger_emergency_sos(
    booking_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Booking).where(Booking.id == booking_id))
    booking = result.scalars().first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    booking.emergency_sos_triggered = True
    await db.commit()

    # Broadcast SOS alert
    await ws_manager.broadcast_to_trip(booking.id, "EMERGENCY_SOS_ALERT", {
        "booking_id": booking.id,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "alert": "EMERGENCY SOS TRIGGERED"
    })

    return {"message": "Emergency SOS broadcasted successfully", "status": "SOS_ACTIVE"}


@router.post("/{booking_id}/rate")
async def rate_driver(
    booking_id: str,
    payload: BookingRateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Booking).where(Booking.id == booking_id))
    booking = result.scalars().first()
    if not booking or booking.status != "COMPLETED":
        raise HTTPException(status_code=400, detail="Cannot rate an uncompleted booking")

    if not booking.driver_id:
        raise HTTPException(status_code=400, detail="No driver assigned to this booking")

    # Check existing rating
    r_check = await db.execute(select(DriverRating).where(DriverRating.booking_id == booking_id))
    if r_check.scalars().first():
        raise HTTPException(status_code=400, detail="Trip already rated")

    rating = DriverRating(
        booking_id=booking.id,
        customer_id=current_user.id,
        driver_id=booking.driver_id,
        stars=payload.stars,
        tags=",".join(payload.tags) if payload.tags else None,
        review_text=payload.review_text,
        tip_amount=payload.tip_amount
    )
    db.add(rating)

    # Handle optional tip from wallet
    if payload.tip_amount > 0:
        w_res = await db.execute(select(Wallet).where(Wallet.user_id == current_user.id))
        wallet = w_res.scalars().first()
        if wallet and wallet.balance >= payload.tip_amount:
            wallet.balance -= payload.tip_amount
            tx = WalletTransaction(
                wallet_id=wallet.id,
                booking_id=booking.id,
                amount=-payload.tip_amount,
                transaction_type="DEBIT",
                description=f"Driver Tip for {booking.booking_code}"
            )
            db.add(tx)

    await db.commit()
    return {"message": "Rating submitted successfully", "stars": payload.stars}
