from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from app.core.database import get_db
from app.models.entities import User, Wallet, WalletTransaction
from app.schemas.schemas import WalletOut, WalletTopUpRequest, WalletTransactionOut
from app.api.deps import get_current_user

router = APIRouter(prefix="/wallet", tags=["Wallet"])


@router.get("", response_model=WalletOut)
async def get_wallet(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(Wallet).options(selectinload(Wallet.transactions)).where(Wallet.user_id == current_user.id)
    )
    wallet = result.scalars().first()
    if not wallet:
        wallet = Wallet(user_id=current_user.id, balance=0.0)
        db.add(wallet)
        await db.commit()
        await db.refresh(wallet, ["transactions"])

    txs = [
        WalletTransactionOut.model_validate(t)
        for t in sorted(wallet.transactions, key=lambda x: x.created_at, reverse=True)
    ]
    return WalletOut(
        balance=wallet.balance,
        currency=wallet.currency,
        transactions=txs
    )


@router.post("/top-up", response_model=WalletOut)
async def top_up_wallet(
    payload: WalletTopUpRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Wallet).where(Wallet.user_id == current_user.id))
    wallet = result.scalars().first()
    if not wallet:
        wallet = Wallet(user_id=current_user.id, balance=0.0)
        db.add(wallet)
        await db.flush()

    wallet.balance += payload.amount
    tx = WalletTransaction(
        wallet_id=wallet.id,
        amount=payload.amount,
        transaction_type="CREDIT",
        description=f"Wallet Top-Up via Card"
    )
    db.add(tx)
    await db.commit()
    await db.refresh(wallet, ["transactions"])

    txs = [
        WalletTransactionOut.model_validate(t)
        for t in sorted(wallet.transactions, key=lambda x: x.created_at, reverse=True)
    ]
    return WalletOut(
        balance=wallet.balance,
        currency=wallet.currency,
        transactions=txs
    )
