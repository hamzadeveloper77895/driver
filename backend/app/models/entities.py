import uuid
from datetime import datetime, timezone
from sqlalchemy import (
    Column, String, Boolean, Integer, Float, DateTime, ForeignKey, Text, Enum
)
from sqlalchemy.orm import relationship
from app.core.database import Base


def generate_uuid() -> str:
    return str(uuid.uuid4())


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    phone = Column(String(20), unique=True, index=True, nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=True)
    hashed_password = Column(String(255), nullable=True)
    full_name = Column(String(100), nullable=False, default="User")
    avatar_url = Column(Text, nullable=True)
    role = Column(String(20), nullable=False, default="CUSTOMER")  # CUSTOMER, DRIVER, ADMIN
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)

    customer_profile = relationship("CustomerProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    driver_profile = relationship("DriverProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    wallet = relationship("Wallet", back_populates="user", uselist=False, cascade="all, delete-orphan")
    vehicles = relationship("Vehicle", back_populates="customer", cascade="all, delete-orphan")
    emergency_contacts = relationship("EmergencyContact", back_populates="customer", cascade="all, delete-orphan")
    customer_bookings = relationship("Booking", foreign_keys="[Booking.customer_id]", back_populates="customer")
    driver_bookings = relationship("Booking", foreign_keys="[Booking.driver_id]", back_populates="driver")


class CustomerProfile(Base):
    __tablename__ = "customer_profiles"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    preferred_payment_mode = Column(String(20), default="WALLET")
    emergency_sos_enabled = Column(Boolean, default=True)

    user = relationship("User", back_populates="customer_profile")


class DriverProfile(Base):
    __tablename__ = "driver_profiles"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    license_number = Column(String(50), unique=True, nullable=False)
    experience_years = Column(Integer, default=3)
    rating_average = Column(Float, default=5.00)
    total_trips = Column(Integer, default=0)
    can_drive_manual = Column(Boolean, default=True)
    can_drive_automatic = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=True)
    duty_status = Column(String(20), default="OFFLINE", index=True)  # ONLINE, OFFLINE, BUSY
    current_lat = Column(Float, nullable=True)
    current_lng = Column(Float, nullable=True)
    last_heartbeat = Column(DateTime(timezone=True), nullable=True)

    user = relationship("User", back_populates="driver_profile")


class Vehicle(Base):
    __tablename__ = "vehicles"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    customer_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    brand = Column(String(50), nullable=False)
    model = Column(String(50), nullable=False)
    year = Column(Integer, nullable=True, default=2022)
    transmission = Column(String(20), nullable=False, default="AUTOMATIC")  # MANUAL, AUTOMATIC
    fuel_type = Column(String(20), default="PETROL")
    plate_number = Column(String(20), nullable=False)
    color = Column(String(30), nullable=True, default="Silver")
    is_default = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=utc_now)

    customer = relationship("User", back_populates="vehicles")
    bookings = relationship("Booking", back_populates="vehicle")


class EmergencyContact(Base):
    __tablename__ = "emergency_contacts"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    customer_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(100), nullable=False)
    phone = Column(String(20), nullable=False)
    relationship_type = Column(String(50), nullable=True, default="Family")
    is_active = Column(Boolean, default=True)

    customer = relationship("User", back_populates="emergency_contacts")


class PricingRule(Base):
    __tablename__ = "pricing_rules"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    city = Column(String(50), nullable=False, default="DefaultCity", index=True)
    service_type = Column(String(30), nullable=False, default="HOURLY_LOCAL")  # HOURLY_LOCAL, OUTSTATION_ROUND_TRIP
    base_hours = Column(Float, default=2.0)
    base_fare = Column(Float, default=25.00)
    extra_minute_rate = Column(Float, default=0.20)
    night_charge_start_hour = Column(Integer, default=22)
    night_charge_end_hour = Column(Integer, default=6)
    night_charge_flat = Column(Float, default=5.00)
    surge_multiplier = Column(Float, default=1.00)
    is_active = Column(Boolean, default=True)


class Booking(Base):
    __tablename__ = "bookings"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    booking_code = Column(String(20), unique=True, index=True, nullable=False)
    customer_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    driver_id = Column(String(36), ForeignKey("users.id"), nullable=True, index=True)
    vehicle_id = Column(String(36), ForeignKey("vehicles.id"), nullable=False)
    service_type = Column(String(30), nullable=False, default="HOURLY_LOCAL")
    booking_type = Column(String(20), default="NOW")  # NOW, SCHEDULED
    scheduled_pickup_time = Column(DateTime(timezone=True), nullable=True)
    status = Column(String(30), default="PENDING", index=True)
    # Statuses: DRAFT, PENDING, DRIVER_ASSIGNED, ON_WAY, ARRIVED, IN_PROGRESS, COMPLETED, CANCELLED, REJECTED, DISPUTED
    
    pickup_address = Column(Text, nullable=False)
    pickup_lat = Column(Float, nullable=False)
    pickup_lng = Column(Float, nullable=False)
    drop_address = Column(Text, nullable=True)
    drop_lat = Column(Float, nullable=True)
    drop_lng = Column(Float, nullable=True)
    
    duration_hours = Column(Float, default=2.0)
    start_otp = Column(String(6), nullable=True)
    trip_start_time = Column(DateTime(timezone=True), nullable=True)
    trip_end_time = Column(DateTime(timezone=True), nullable=True)
    
    estimated_fare = Column(Float, default=0.0)
    final_fare = Column(Float, nullable=True)
    payment_mode = Column(String(20), default="WALLET")  # WALLET, CARD, CASH
    payment_status = Column(String(20), default="PENDING")  # PENDING, PAID, REFUNDED
    cancellation_reason = Column(Text, nullable=True)
    cancellation_fee = Column(Float, default=0.0)
    emergency_sos_triggered = Column(Boolean, default=False)
    
    created_at = Column(DateTime(timezone=True), default=utc_now, index=True)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)

    customer = relationship("User", foreign_keys=[customer_id], back_populates="customer_bookings")
    driver = relationship("User", foreign_keys=[driver_id], back_populates="driver_bookings")
    vehicle = relationship("Vehicle", back_populates="bookings")
    telemetry_logs = relationship("TripTelemetry", back_populates="booking", cascade="all, delete-orphan")
    chat_messages = relationship("ChatMessage", back_populates="booking", cascade="all, delete-orphan")
    rating = relationship("DriverRating", back_populates="booking", uselist=False)


class TripTelemetry(Base):
    __tablename__ = "trip_telemetry"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    booking_id = Column(String(36), ForeignKey("bookings.id", ondelete="CASCADE"), nullable=False, index=True)
    driver_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    bearing = Column(Float, default=0.0)
    speed = Column(Float, default=0.0)
    recorded_at = Column(DateTime(timezone=True), default=utc_now)

    booking = relationship("Booking", back_populates="telemetry_logs")


class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    booking_id = Column(String(36), ForeignKey("bookings.id", ondelete="CASCADE"), nullable=False, index=True)
    sender_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    receiver_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    message = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False)
    sent_at = Column(DateTime(timezone=True), default=utc_now)

    booking = relationship("Booking", back_populates="chat_messages")


class Wallet(Base):
    __tablename__ = "wallets"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    balance = Column(Float, default=50.00)  # default $50 bonus for new accounts
    currency = Column(String(10), default="USD")
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)

    user = relationship("User", back_populates="wallet")
    transactions = relationship("WalletTransaction", back_populates="wallet", cascade="all, delete-orphan")


class WalletTransaction(Base):
    __tablename__ = "wallet_transactions"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    wallet_id = Column(String(36), ForeignKey("wallets.id", ondelete="CASCADE"), nullable=False, index=True)
    booking_id = Column(String(36), ForeignKey("bookings.id"), nullable=True)
    amount = Column(Float, nullable=False)
    transaction_type = Column(String(20), nullable=False)  # CREDIT, DEBIT
    description = Column(String(255), nullable=False)
    created_at = Column(DateTime(timezone=True), default=utc_now)

    wallet = relationship("Wallet", back_populates="transactions")


class DriverRating(Base):
    __tablename__ = "driver_ratings"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    booking_id = Column(String(36), ForeignKey("bookings.id"), unique=True, nullable=False)
    customer_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    driver_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    stars = Column(Integer, nullable=False)
    tags = Column(String(255), nullable=True)
    review_text = Column(Text, nullable=True)
    tip_amount = Column(Float, default=0.0)
    created_at = Column(DateTime(timezone=True), default=utc_now)

    booking = relationship("Booking", back_populates="rating")
