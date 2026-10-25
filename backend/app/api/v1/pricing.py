from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.database import get_db
from app.models.entities import PricingRule
from app.schemas.schemas import FareEstimateRequest, FareEstimateOut
from app.services.pricing_service import PricingService

router = APIRouter(prefix="/pricing", tags=["Pricing"])


@router.post("/estimate", response_model=FareEstimateOut)
async def get_fare_estimate(payload: FareEstimateRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(PricingRule)
        .where(PricingRule.service_type == payload.service_type)
        .where(PricingRule.is_active == True)
    )
    rule = result.scalars().first()

    estimate = PricingService.estimate_fare(
        rule=rule,
        service_type=payload.service_type,
        duration_hours=payload.duration_hours,
        pickup_lat=payload.pickup_lat,
        pickup_lng=payload.pickup_lng,
        drop_lat=payload.drop_lat,
        drop_lng=payload.drop_lng,
        promo_code=payload.promo_code
    )
    return estimate
