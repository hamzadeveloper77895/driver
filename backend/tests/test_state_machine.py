import pytest
from app.models.entities import Booking
from app.services.state_machine import BookingStateMachine, InvalidStateTransitionError


def create_mock_booking(status: str = "DRAFT", start_otp: str = "5824") -> Booking:
    return Booking(
        id="test-booking-id",
        booking_code="BK-123456",
        customer_id="cust-1",
        vehicle_id="veh-1",
        service_type="HOURLY_LOCAL",
        pickup_address="123 Main St",
        pickup_lat=12.9716,
        pickup_lng=77.5946,
        estimated_fare=35.00,
        cancellation_fee=0.0,
        status=status,
        start_otp=start_otp
    )


def test_transition_draft_to_pending():
    booking = create_mock_booking(status="DRAFT")
    BookingStateMachine.transition(booking, "PENDING", actor_role="CUSTOMER")
    assert booking.status == "PENDING"


def test_transition_pending_to_driver_assigned():
    booking = create_mock_booking(status="PENDING")
    BookingStateMachine.transition(booking, "DRIVER_ASSIGNED", actor_role="DRIVER", driver_id="driver-99")
    assert booking.status == "DRIVER_ASSIGNED"
    assert booking.driver_id == "driver-99"
    assert len(booking.start_otp) == 4


def test_transition_pending_to_driver_assigned_missing_driver():
    booking = create_mock_booking(status="PENDING")
    with pytest.raises(InvalidStateTransitionError):
        BookingStateMachine.transition(booking, "DRIVER_ASSIGNED", actor_role="DRIVER", driver_id=None)


def test_transition_pending_to_cancelled():
    booking = create_mock_booking(status="PENDING")
    BookingStateMachine.transition(booking, "CANCELLED", actor_role="CUSTOMER", reason="Changed mind")
    assert booking.status == "CANCELLED"
    assert booking.cancellation_reason == "Changed mind"
    assert booking.cancellation_fee == 0.0


def test_transition_pending_to_rejected():
    booking = create_mock_booking(status="PENDING")
    BookingStateMachine.transition(booking, "REJECTED", actor_role="SYSTEM")
    assert booking.status == "REJECTED"


def test_transition_driver_assigned_to_on_way():
    booking = create_mock_booking(status="DRIVER_ASSIGNED")
    BookingStateMachine.transition(booking, "ON_WAY", actor_role="DRIVER")
    assert booking.status == "ON_WAY"


def test_transition_driver_assigned_to_cancelled():
    booking = create_mock_booking(status="DRIVER_ASSIGNED")
    BookingStateMachine.transition(booking, "CANCELLED", actor_role="DRIVER", reason="Driver emergency")
    assert booking.status == "CANCELLED"


def test_transition_on_way_to_arrived():
    booking = create_mock_booking(status="ON_WAY")
    BookingStateMachine.transition(booking, "ARRIVED", actor_role="DRIVER")
    assert booking.status == "ARRIVED"


def test_transition_on_way_to_cancelled():
    booking = create_mock_booking(status="ON_WAY")
    BookingStateMachine.transition(booking, "CANCELLED", actor_role="CUSTOMER", reason="Delay too long")
    assert booking.status == "CANCELLED"
    assert booking.cancellation_fee == 5.00  # Late cancellation fee


def test_transition_arrived_to_in_progress_valid_otp():
    booking = create_mock_booking(status="ARRIVED", start_otp="4321")
    BookingStateMachine.transition(booking, "IN_PROGRESS", actor_role="DRIVER", otp="4321")
    assert booking.status == "IN_PROGRESS"
    assert booking.trip_start_time is not None


def test_transition_arrived_to_in_progress_invalid_otp():
    booking = create_mock_booking(status="ARRIVED", start_otp="4321")
    with pytest.raises(InvalidStateTransitionError):
        BookingStateMachine.transition(booking, "IN_PROGRESS", actor_role="DRIVER", otp="9999")
    assert booking.status == "ARRIVED"


def test_transition_arrived_to_cancelled():
    booking = create_mock_booking(status="ARRIVED")
    BookingStateMachine.transition(booking, "CANCELLED", actor_role="CUSTOMER", reason="Customer cancelled at arrival")
    assert booking.status == "CANCELLED"
    assert booking.cancellation_fee == 5.00


def test_transition_in_progress_to_completed():
    booking = create_mock_booking(status="IN_PROGRESS")
    BookingStateMachine.transition(booking, "COMPLETED", actor_role="DRIVER", final_fare=42.50)
    assert booking.status == "COMPLETED"
    assert booking.trip_end_time is not None
    assert booking.final_fare == 42.50


def test_transition_completed_to_disputed():
    booking = create_mock_booking(status="COMPLETED")
    BookingStateMachine.transition(booking, "DISPUTED", actor_role="CUSTOMER")
    assert booking.status == "DISPUTED"


def test_transition_disputed_to_completed():
    booking = create_mock_booking(status="DISPUTED")
    BookingStateMachine.transition(booking, "COMPLETED", actor_role="ADMIN")
    assert booking.status == "COMPLETED"


def test_illegal_skip_transitions_raise_error():
    # Cannot jump from PENDING to IN_PROGRESS
    booking = create_mock_booking(status="PENDING")
    with pytest.raises(InvalidStateTransitionError):
        BookingStateMachine.transition(booking, "IN_PROGRESS", actor_role="DRIVER")

    # Cannot jump from COMPLETED to ON_WAY
    booking_done = create_mock_booking(status="COMPLETED")
    with pytest.raises(InvalidStateTransitionError):
        BookingStateMachine.transition(booking_done, "ON_WAY", actor_role="DRIVER")
