from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict


# Auth
class RequestOtpSchema(BaseModel):
    phone: str
    role: str = "CUSTOMER"


class VerifyOtpSchema(BaseModel):
    phone: str
    otp: str
    role: Optional[str] = None


class SwitchRoleSchema(BaseModel):
    role: str


class RefreshTokenSchema(BaseModel):
    refresh_token: str


class UserOut(BaseModel):
    id: str
    phone: str
    email: Optional[str] = None
    full_name: str
    avatar_url: Optional[str] = None
    role: str
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    is_new_user: bool = False
    user: UserOut


class UserProfileUpdate(BaseModel):
    full_name: Optional[str] = None
    email: Optional[str] = None
    avatar_url: Optional[str] = None


# Vehicles
class VehicleCreate(BaseModel):
    brand: str
    model: str
    year: Optional[int] = 2022
    transmission: str = "AUTOMATIC"  # MANUAL, AUTOMATIC
    fuel_type: str = "PETROL"
    plate_number: str
    color: Optional[str] = "Silver"


class VehicleOut(BaseModel):
    id: str
    customer_id: str
    brand: str
    model: str
    year: Optional[int]
    transmission: str
    fuel_type: str
    plate_number: str
    color: Optional[str]
    is_default: bool
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)


# Emergency Contacts
class EmergencyContactCreate(BaseModel):
    name: str
    phone: str
    relationship_type: Optional[str] = "Family"


class EmergencyContactOut(BaseModel):
    id: str
    customer_id: str
    name: str
    phone: str
    relationship_type: Optional[str]
    is_active: bool
    model_config = ConfigDict(from_attributes=True)


# Pricing
class FareEstimateRequest(BaseModel):
    service_type: str = "HOURLY_LOCAL"
    duration_hours: float = 2.0
    pickup_lat: float
    pickup_lng: float
    drop_lat: Optional[float] = None
    drop_lng: Optional[float] = None
    promo_code: Optional[str] = None


class FareEstimateOut(BaseModel):
    base_fare: float
    extra_minute_rate: float
    estimated_duration_minutes: int
    estimated_distance_km: float
    night_charges: float
    taxes: float
    discount: float
    total_fare: float
    currency: str = "USD"


# Driver Profile
class DriverSummary(BaseModel):
    id: str
    full_name: str
    avatar_url: Optional[str] = None
    phone: str
    rating_average: float
    total_trips: int
    current_lat: Optional[float] = None
    current_lng: Optional[float] = None
    model_config = ConfigDict(from_attributes=True)


# Bookings
class BookingCreate(BaseModel):
    vehicle_id: str
    service_type: str = "HOURLY_LOCAL"
    booking_type: str = "NOW"
    scheduled_pickup_time: Optional[datetime] = None
    duration_hours: float = 2.0
    pickup_address: str
    pickup_lat: float
    pickup_lng: float
    drop_address: Optional[str] = None
    drop_lat: Optional[float] = None
    drop_lng: Optional[float] = None
    payment_mode: str = "WALLET"
    promo_code: Optional[str] = None


class BookingOut(BaseModel):
    id: str
    booking_code: str
    customer_id: str
    driver_id: Optional[str] = None
    vehicle_id: str
    service_type: str
    booking_type: str
    status: str
    pickup_address: str
    pickup_lat: float
    pickup_lng: float
    drop_address: Optional[str] = None
    drop_lat: Optional[float] = None
    drop_lng: Optional[float] = None
    start_otp: Optional[str] = None
    trip_start_time: Optional[datetime] = None
    trip_end_time: Optional[datetime] = None
    estimated_fare: float
    final_fare: Optional[float] = None
    payment_mode: str
    payment_status: str
    emergency_sos_triggered: bool = False
    created_at: datetime
    driver: Optional[DriverSummary] = None
    vehicle: Optional[VehicleOut] = None
    model_config = ConfigDict(from_attributes=True)


class BookingCancelRequest(BaseModel):
    reason: Optional[str] = "Cancelled by user"


class BookingRateRequest(BaseModel):
    stars: int = Field(ge=1, le=5)
    tags: Optional[List[str]] = []
    review_text: Optional[str] = None
    tip_amount: float = 0.0


# Driver Telemetry & Operations
class DutyStatusUpdate(BaseModel):
    duty_status: str  # ONLINE, OFFLINE


class DriverTelemetryCreate(BaseModel):
    latitude: float
    longitude: float
    bearing: float = 0.0
    speed: float = 0.0


class StartTripRequest(BaseModel):
    otp: str


# Wallet
class WalletTransactionOut(BaseModel):
    id: str
    amount: float
    transaction_type: str
    description: str
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)


class WalletOut(BaseModel):
    balance: float
    currency: str
    transactions: List[WalletTransactionOut] = []


class WalletTopUpRequest(BaseModel):
    amount: float = Field(gt=0)
