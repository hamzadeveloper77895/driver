from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.database import get_db
from app.models.entities import User, Vehicle, EmergencyContact
from app.schemas.schemas import VehicleCreate, VehicleOut, EmergencyContactCreate, EmergencyContactOut
from app.api.deps import get_current_user

router = APIRouter(tags=["Garage & Contacts"])


# Vehicles
@router.get("/garage/vehicles", response_model=List[VehicleOut])
async def list_vehicles(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(Vehicle).where(Vehicle.customer_id == current_user.id).order_by(Vehicle.created_at.desc())
    )
    return [VehicleOut.model_validate(v) for v in result.scalars().all()]


@router.post("/garage/vehicles", response_model=VehicleOut, status_code=status.HTTP_201_CREATED)
async def add_vehicle(
    payload: VehicleCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Check if this is customer's first vehicle (make it default)
    count_res = await db.execute(select(Vehicle).where(Vehicle.customer_id == current_user.id))
    existing_count = len(count_res.scalars().all())

    vehicle = Vehicle(
        customer_id=current_user.id,
        brand=payload.brand.strip(),
        model=payload.model.strip(),
        year=payload.year,
        transmission=payload.transmission.upper().strip(),
        fuel_type=payload.fuel_type.upper().strip(),
        plate_number=payload.plate_number.upper().strip(),
        color=payload.color,
        is_default=(existing_count == 0)
    )
    db.add(vehicle)
    await db.commit()
    await db.refresh(vehicle)
    return VehicleOut.model_validate(vehicle)


@router.delete("/garage/vehicles/{vehicle_id}")
async def delete_vehicle(
    vehicle_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(Vehicle).where(Vehicle.id == vehicle_id, Vehicle.customer_id == current_user.id)
    )
    vehicle = result.scalars().first()
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")

    await db.delete(vehicle)
    await db.commit()
    return {"message": "Vehicle deleted successfully"}


# Emergency Contacts
@router.get("/emergency-contacts", response_model=List[EmergencyContactOut])
async def list_emergency_contacts(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(EmergencyContact).where(EmergencyContact.customer_id == current_user.id)
    )
    return [EmergencyContactOut.model_validate(c) for c in result.scalars().all()]


@router.post("/emergency-contacts", response_model=EmergencyContactOut, status_code=status.HTTP_201_CREATED)
async def add_emergency_contact(
    payload: EmergencyContactCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    contact = EmergencyContact(
        customer_id=current_user.id,
        name=payload.name.strip(),
        phone=payload.phone.strip(),
        relationship_type=payload.relationship_type
    )
    db.add(contact)
    await db.commit()
    await db.refresh(contact)
    return EmergencyContactOut.model_validate(contact)


@router.delete("/emergency-contacts/{contact_id}")
async def delete_emergency_contact(
    contact_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(EmergencyContact).where(
            EmergencyContact.id == contact_id,
            EmergencyContact.customer_id == current_user.id
        )
    )
    contact = result.scalars().first()
    if not contact:
        raise HTTPException(status_code=404, detail="Contact not found")

    await db.delete(contact)
    await db.commit()
    return {"message": "Contact deleted successfully"}
