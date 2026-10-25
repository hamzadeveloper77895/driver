import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_driver_duty_and_telemetry(client: AsyncClient, driver_auth_headers):
    # Toggle Online
    duty_resp = await client.put("/api/v1/driver/duty-status", headers=driver_auth_headers, json={
        "duty_status": "ONLINE"
    })
    assert duty_resp.status_code == 200
    assert duty_resp.json()["duty_status"] == "ONLINE"

    # Ingest Telemetry
    telem_resp = await client.post("/api/v1/driver/telemetry", headers=driver_auth_headers, json={
        "latitude": 12.9716,
        "longitude": 77.5946,
        "bearing": 90.0,
        "speed": 35.0
    })
    assert telem_resp.status_code == 200
    assert telem_resp.json()["recorded"] is True

    # Check offers endpoint
    offer_resp = await client.get("/api/v1/driver/offers", headers=driver_auth_headers)
    assert offer_resp.status_code == 200
