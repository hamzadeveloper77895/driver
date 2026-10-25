import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_garage_vehicle_crud(client: AsyncClient, customer_auth_headers):
    # List vehicles
    list_resp = await client.get("/api/v1/garage/vehicles", headers=customer_auth_headers)
    assert list_resp.status_code == 200
    vehicles = list_resp.json()
    assert len(vehicles) >= 2

    # Add new vehicle
    add_resp = await client.post("/api/v1/garage/vehicles", headers=customer_auth_headers, json={
        "brand": "Toyota",
        "model": "Innova",
        "year": 2024,
        "transmission": "AUTOMATIC",
        "fuel_type": "DIESEL",
        "plate_number": "KA04XY9999",
        "color": "Silver"
    })
    assert add_resp.status_code == 201
    new_veh = add_resp.json()
    assert new_veh["brand"] == "Toyota"
    veh_id = new_veh["id"]

    # Delete vehicle
    del_resp = await client.delete(f"/api/v1/garage/vehicles/{veh_id}", headers=customer_auth_headers)
    assert del_resp.status_code == 200


@pytest.mark.asyncio
async def test_emergency_contacts(client: AsyncClient, customer_auth_headers):
    add_resp = await client.post("/api/v1/emergency-contacts", headers=customer_auth_headers, json={
        "name": "Jane Doe",
        "phone": "+919876500000",
        "relationship_type": "Spouse"
    })
    assert add_resp.status_code == 201
    contact = add_resp.json()
    assert contact["name"] == "Jane Doe"
    contact_id = contact["id"]

    list_resp = await client.get("/api/v1/emergency-contacts", headers=customer_auth_headers)
    assert list_resp.status_code == 200
    assert len(list_resp.json()) >= 1

    del_resp = await client.delete(f"/api/v1/emergency-contacts/{contact_id}", headers=customer_auth_headers)
    assert del_resp.status_code == 200
