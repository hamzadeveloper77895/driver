import pytest
from httpx import AsyncClient
from app.services.pricing_service import PricingService


@pytest.mark.asyncio
async def test_fare_estimate_api(client: AsyncClient, customer_auth_headers):
    resp = await client.post("/api/v1/pricing/estimate", headers=customer_auth_headers, json={
        "service_type": "HOURLY_LOCAL",
        "duration_hours": 3.0,
        "pickup_lat": 12.9716,
        "pickup_lng": 77.5946,
        "drop_lat": 12.9352,
        "drop_lng": 77.6245,
        "promo_code": "WELCOME5"
    })
    assert resp.status_code == 200
    data = resp.json()
    assert data["base_fare"] == 25.00
    assert data["extra_minute_rate"] == 0.20
    assert data["estimated_duration_minutes"] == 180
    assert data["discount"] == 5.00
    assert data["total_fare"] > 0.0


def test_distance_calculation():
    dist = PricingService.calculate_distance(12.9716, 77.5946, 12.9352, 77.6245)
    assert 4.0 <= dist <= 6.0
