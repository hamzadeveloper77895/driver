from datetime import datetime, timezone
from typing import Dict, Set, Optional
from app.models.entities import Booking


class InvalidStateTransitionError(Exception):
    def __init__(self, current_status: str, target_status: str, reason: str = ""):
        self.current_status = current_status
        self.target_status = target_status
        self.reason = reason
        super().__init__(
            f"Cannot transition booking from {current_status} to {target_status}. {reason}".strip()
        )


class BookingStateMachine:
    # Allowed transitions mapping: source_status -> set of allowed target_statuses
    ALLOWED_TRANSITIONS: Dict[str, Set[str]] = {
        "DRAFT": {"PENDING", "CANCELLED"},
        "PENDING": {"DRIVER_ASSIGNED", "REJECTED", "CANCELLED"},
        "DRIVER_ASSIGNED": {"ON_WAY", "CANCELLED"},
        "ON_WAY": {"ARRIVED", "CANCELLED"},
        "ARRIVED": {"IN_PROGRESS", "CANCELLED"},
        "IN_PROGRESS": {"COMPLETED", "DISPUTED"},
        "COMPLETED": {"DISPUTED"},
        "DISPUTED": {"COMPLETED"},
        "CANCELLED": set(),
        "REJECTED": set(),
    }

    @classmethod
    def can_transition(cls, current_status: str, target_status: str) -> bool:
        return target_status in cls.ALLOWED_TRANSITIONS.get(current_status, set())

    @classmethod
    def transition(
        cls,
        booking: Booking,
        target_status: str,
        actor_role: str,
        driver_id: Optional[str] = None,
        otp: Optional[str] = None,
        reason: Optional[str] = None,
        final_fare: Optional[float] = None
    ) -> Booking:
        current_status = booking.status
        now = datetime.now(timezone.utc)

        if not cls.can_transition(current_status, target_status):
            raise InvalidStateTransitionError(
                current_status,
                target_status,
                f"Transition not allowed by state machine rule."
            )

        # Transition specific guards & side effects
        if target_status == "DRIVER_ASSIGNED":
            if not driver_id:
                raise InvalidStateTransitionError(current_status, target_status, "driver_id is required.")
            booking.driver_id = driver_id
            # Generate 4-digit start OTP if not present
            import random
            booking.start_otp = "".join(random.choices("0123456789", k=4))

        elif target_status == "IN_PROGRESS":
            if not otp:
                raise InvalidStateTransitionError(current_status, target_status, "Customer OTP is required to start trip.")
            if str(otp).strip() != str(booking.start_otp).strip():
                raise InvalidStateTransitionError(current_status, target_status, "Invalid customer start OTP.")
            booking.trip_start_time = now

        elif target_status == "COMPLETED":
            booking.trip_end_time = now
            if final_fare is not None:
                booking.final_fare = final_fare
            elif booking.final_fare is None:
                booking.final_fare = booking.estimated_fare

        elif target_status == "CANCELLED":
            booking.cancellation_reason = reason or "Cancelled by user"
            # Apply cancellation fee if cancelled after driver arrival or > 5 min
            if current_status in ["ON_WAY", "ARRIVED"]:
                booking.cancellation_fee = 5.00

        booking.status = target_status
        booking.updated_at = now
        return booking
