from datetime import datetime, timezone
import math
from typing import Optional
from app.models.entities import PricingRule
from app.schemas.schemas import FareEstimateOut


class PricingService:
    @staticmethod
    def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Haversine distance in kilometers between two coordinates."""
        R = 6371.0
        phi1 = math.radians(lat1)
        phi2 = math.radians(lat2)
        delta_phi = math.radians(lat2 - lat1)
        delta_lambda = math.radians(lon2 - lon1)

        a = (
            math.sin(delta_phi / 2.0) ** 2
            + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2.0) ** 2
        )
        c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
        return round(R * c, 2)

    @classmethod
    def estimate_fare(
        cls,
        rule: Optional[PricingRule],
        service_type: str,
        duration_hours: float,
        pickup_lat: float,
        pickup_lng: float,
        drop_lat: Optional[float] = None,
        drop_lng: Optional[float] = None,
        promo_code: Optional[str] = None
    ) -> FareEstimateOut:
        base_fare = rule.base_fare if rule else 25.00
        extra_minute_rate = rule.extra_minute_rate if rule else 0.20
        night_flat = rule.night_charge_flat if rule else 5.00
        surge = rule.surge_multiplier if rule else 1.00

        # Base hours check
        base_hours = rule.base_hours if rule else 2.0
        extra_hours = max(0.0, duration_hours - base_hours)
        extra_minutes = int(extra_hours * 60)
        extra_fare = extra_minutes * extra_minute_rate

        # Night surcharge check (current time in UTC/local hour between 22 and 6)
        current_hour = datetime.now(timezone.utc).hour
        night_charges = night_flat if (current_hour >= 22 or current_hour < 6) else 0.0

        # Estimated distance
        distance_km = 0.0
        if drop_lat is not None and drop_lng is not None:
            distance_km = cls.calculate_distance(pickup_lat, pickup_lng, drop_lat, drop_lng)
        else:
            distance_km = duration_hours * 15.0  # approximate 15 km/h in city traffic

        subtotal = (base_fare + extra_fare + night_charges) * surge
        
        # Promo code discount
        discount = 0.0
        if promo_code:
            code_clean = promo_code.strip().upper()
            if code_clean in ["WELCOME5", "CHAUFFEUR5", "FIRST5"]:
                discount = min(5.00, subtotal)
            elif code_clean in ["DRIVE10", "SAVE10"]:
                discount = min(10.00, subtotal)

        taxable_amount = max(0.0, subtotal - discount)
        taxes = round(taxable_amount * 0.18, 2)
        total_fare = round(taxable_amount + taxes, 2)

        return FareEstimateOut(
            base_fare=round(base_fare, 2),
            extra_minute_rate=round(extra_minute_rate, 2),
            estimated_duration_minutes=int(duration_hours * 60),
            estimated_distance_km=distance_km,
            night_charges=round(night_charges, 2),
            taxes=taxes,
            discount=round(discount, 2),
            total_fare=total_fare,
            currency="USD"
        )
