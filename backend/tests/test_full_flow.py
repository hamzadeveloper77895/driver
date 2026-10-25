import pytest
from httpx import AsyncClient
from app.simulator import simulate_booking_lifecycle
from tests.conftest import TestingSessionLocal


@pytest.mark.asyncio
async def test_full_booking_and_simulation(client: AsyncClient, customer_auth_headers, driver_auth_headers):
    # 1. Customer creates a booking
    create_resp = await client.post("/api/v1/bookings", headers=customer_auth_headers, json={
        "vehicle_id": "veh-auto-1234",
        "service_type": "HOURLY_LOCAL",
        "booking_type": "NOW",
        "duration_hours": 2.0,
        "pickup_address": "MG Road, Bengaluru",
        "pickup_lat": 12.9716,
        "pickup_lng": 77.5946,
        "drop_address": "Indiranagar, Bengaluru",
        "drop_lat": 12.9784,
        "drop_lng": 77.6408,
        "payment_mode": "WALLET"
    })
    assert create_resp.status_code == 201
    booking = create_resp.json()
    booking_id = booking["id"]
    assert booking["status"] == "PENDING"
    assert booking["estimated_fare"] > 0

    # 2. Check active booking
    active_resp = await client.get("/api/v1/bookings/active", headers=customer_auth_headers)
    assert active_resp.status_code == 200
    assert active_resp.json()["id"] == booking_id

    # 3. Run autonomous driver simulator on this booking
    success = await simulate_booking_lifecycle(booking_id=booking_id, speed_multiplier=100.0, session_factory=TestingSessionLocal)
    assert success is True

    # 4. Verify completed state via API
    completed_resp = await client.get(f"/api/v1/bookings/{booking_id}", headers=customer_auth_headers)
    assert completed_resp.status_code == 200
    completed_booking = completed_resp.json()
    assert completed_booking["status"] == "COMPLETED"
    assert completed_booking["payment_status"] == "PAID"
    assert completed_booking["final_fare"] > 0

    # 5. Customer rates the driver
    rate_resp = await client.post(f"/api/v1/bookings/{booking_id}/rate", headers=customer_auth_headers, json={
        "stars": 5,
        "tags": ["Punctual", "Smooth Driving", "Courteous"],
        "review_text": "Excellent chauffeur, drove very smoothly!",
        "tip_amount": 5.0
    })
    assert rate_resp.status_code == 200
    assert rate_resp.json()["stars"] == 5

    # 6. Check driver earnings endpoint
    earnings_resp = await client.get("/api/v1/driver/earnings", headers=driver_auth_headers)
    assert earnings_resp.status_code == 200
    assert earnings_resp.json()["trips_completed"] >= 1
