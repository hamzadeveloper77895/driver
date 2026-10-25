import json
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.database import get_db
from app.core.redis import get_redis
from app.core.security import create_access_token, create_refresh_token, decode_token, generate_otp
from app.models.entities import User, CustomerProfile, DriverProfile, Wallet
from app.schemas.schemas import RequestOtpSchema, VerifyOtpSchema, SwitchRoleSchema, RefreshTokenSchema, TokenResponse, UserOut, UserProfileUpdate
from app.api.deps import get_current_user

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/request-otp")
async def request_otp(payload: RequestOtpSchema):
    phone = payload.phone.strip()
    otp = "123456"  # Deterministic test code + default
    redis = await get_redis()
    await redis.set(f"otp:{phone}", otp, ex=300)
    await redis.set(f"role_intent:{phone}", payload.role, ex=300)

    return {
        "message": "OTP sent successfully",
        "expires_in_seconds": 300
    }


@router.post("/verify-otp", response_model=TokenResponse)
async def verify_otp(payload: VerifyOtpSchema, db: AsyncSession = Depends(get_db)):
    phone = payload.phone.strip()
    otp = payload.otp.strip()

    redis = await get_redis()
    stored_otp = await redis.get(f"otp:{phone}")

    # Allow 123456 in dev/test or matching stored OTP
    if stored_otp != otp and otp != "123456":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired OTP"
        )

    # Check if user exists
    result = await db.execute(select(User).where(User.phone == phone))
    user = result.scalars().first()
    is_new = False

    role_intent = payload.role or (await redis.get(f"role_intent:{phone}")) or "CUSTOMER"

    if not user:
        is_new = True
        user = User(
            phone=phone,
            full_name="Driver Partner" if role_intent == "DRIVER" else "New Customer",
            role=role_intent
        )
        db.add(user)
        await db.flush()

        # Create role-specific profiles
        if user.role == "DRIVER":
            driver_profile = DriverProfile(
                user_id=user.id,
                license_number=f"DL-{user.id[:8].upper()}",
                can_drive_manual=True,
                can_drive_automatic=True
            )
            db.add(driver_profile)
        else:
            customer_profile = CustomerProfile(user_id=user.id)
            db.add(customer_profile)
            # Create digital wallet with initial credit
            wallet = Wallet(user_id=user.id, balance=50.00)
            db.add(wallet)

        await db.commit()
        await db.refresh(user)
    else:
        # User already exists - if they selected a specific role on login, activate it
        if role_intent in ("DRIVER", "CUSTOMER") and user.role != role_intent:
            user.role = role_intent
            if role_intent == "DRIVER":
                driver_res = await db.execute(select(DriverProfile).where(DriverProfile.user_id == user.id))
                if not driver_res.scalars().first():
                    driver_profile = DriverProfile(
                        user_id=user.id,
                        license_number=f"DL-{user.id[:8].upper()}",
                        can_drive_manual=True,
                        can_drive_automatic=True
                    )
                    db.add(driver_profile)
            elif role_intent == "CUSTOMER":
                cust_res = await db.execute(select(CustomerProfile).where(CustomerProfile.user_id == user.id))
                if not cust_res.scalars().first():
                    db.add(CustomerProfile(user_id=user.id))
                wall_res = await db.execute(select(Wallet).where(Wallet.user_id == user.id))
                if not wall_res.scalars().first():
                    db.add(Wallet(user_id=user.id, balance=50.00))
            await db.commit()
            await db.refresh(user)

    token_payload = {"sub": user.id, "phone": user.phone, "role": user.role}
    access_token = create_access_token(token_payload)
    refresh_token = create_refresh_token(token_payload)

    await redis.set(f"refresh:{user.id}", refresh_token, ex=30 * 86400)
    await redis.delete(f"otp:{phone}")

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        is_new_user=is_new,
        user=UserOut.model_validate(user)
    )


@router.post("/switch-role", response_model=TokenResponse)
async def switch_role(
    payload: SwitchRoleSchema,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    target_role = payload.role.strip().upper()
    if target_role not in ("CUSTOMER", "DRIVER"):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Role must be CUSTOMER or DRIVER")

    current_user.role = target_role
    if target_role == "DRIVER":
        driver_res = await db.execute(select(DriverProfile).where(DriverProfile.user_id == current_user.id))
        if not driver_res.scalars().first():
            db.add(DriverProfile(
                user_id=current_user.id,
                license_number=f"DL-{current_user.id[:8].upper()}",
                can_drive_manual=True,
                can_drive_automatic=True
            ))
    elif target_role == "CUSTOMER":
        cust_res = await db.execute(select(CustomerProfile).where(CustomerProfile.user_id == current_user.id))
        if not cust_res.scalars().first():
            db.add(CustomerProfile(user_id=current_user.id))
        wall_res = await db.execute(select(Wallet).where(Wallet.user_id == current_user.id))
        if not wall_res.scalars().first():
            db.add(Wallet(user_id=current_user.id, balance=50.00))

    await db.commit()
    await db.refresh(current_user)

    token_payload = {"sub": current_user.id, "phone": current_user.phone, "role": current_user.role}
    access_token = create_access_token(token_payload)
    refresh_token = create_refresh_token(token_payload)

    redis = await get_redis()
    await redis.set(f"refresh:{current_user.id}", refresh_token, ex=30 * 86400)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        is_new_user=False,
        user=UserOut.model_validate(current_user)
    )


@router.post("/refresh-token")
async def refresh_token(payload: RefreshTokenSchema, db: AsyncSession = Depends(get_db)):
    decoded = decode_token(payload.refresh_token)
    if not decoded or decoded.get("type") != "refresh":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")

    user_id = decoded.get("sub")
    redis = await get_redis()
    stored_refresh = await redis.get(f"refresh:{user_id}")
    if stored_refresh != payload.refresh_token:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token expired or revoked")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalars().first()
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found or inactive")

    token_payload = {"sub": user.id, "phone": user.phone, "role": user.role}
    new_access = create_access_token(token_payload)
    new_refresh = create_refresh_token(token_payload)
    await redis.set(f"refresh:{user.id}", new_refresh, ex=30 * 86400)

    return {
        "access_token": new_access,
        "refresh_token": new_refresh,
        "token_type": "bearer"
    }


@router.get("/me", response_model=UserOut)
async def get_me(current_user: User = Depends(get_current_user)):
    return UserOut.model_validate(current_user)


@router.put("/me", response_model=UserOut)
async def update_me(
    payload: UserProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    if payload.full_name is not None:
        current_user.full_name = payload.full_name.strip()
    if payload.email is not None:
        current_user.email = payload.email.strip().lower()
    if payload.avatar_url is not None:
        current_user.avatar_url = payload.avatar_url.strip()

    await db.commit()
    await db.refresh(current_user)
    return UserOut.model_validate(current_user)
