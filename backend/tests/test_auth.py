import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_request_and_verify_otp(client: AsyncClient):
    # Request OTP
    req_resp = await client.post("/api/v1/auth/request-otp", json={
        "phone": "+919876543999",
        "role": "CUSTOMER"
    })
    assert req_resp.status_code == 200
    assert "expires_in_seconds" in req_resp.json()

    # Verify OTP
    verify_resp = await client.post("/api/v1/auth/verify-otp", json={
        "phone": "+919876543999",
        "otp": "123456"
    })
    assert verify_resp.status_code == 200
    data = verify_resp.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["is_new_user"] is True
    assert data["user"]["phone"] == "+919876543999"

    # Fetch /me
    access_token = data["access_token"]
    me_resp = await client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {access_token}"})
    assert me_resp.status_code == 200
    assert me_resp.json()["phone"] == "+919876543999"

    # Refresh Token
    refresh_token = data["refresh_token"]
    ref_resp = await client.post("/api/v1/auth/refresh-token", json={
        "refresh_token": refresh_token
    })
    assert ref_resp.status_code == 200
    assert "access_token" in ref_resp.json()


@pytest.mark.asyncio
async def test_invalid_otp(client: AsyncClient):
    resp = await client.post("/api/v1/auth/verify-otp", json={
        "phone": "+919876543111",
        "otp": "000000"
    })
    assert resp.status_code == 400
