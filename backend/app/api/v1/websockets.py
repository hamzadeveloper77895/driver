import json
import logging
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from app.core.database import AsyncSessionLocal
from app.models.entities import Booking, User, ChatMessage
from app.services.websocket_manager import ws_manager

logger = logging.getLogger(__name__)
router = APIRouter(tags=["WebSockets"])


@router.websocket("/ws/trips/{booking_id}")
async def trip_live_tracking_websocket(websocket: WebSocket, booking_id: str):
    # Fetch snapshot from database
    snapshot = None
    async with AsyncSessionLocal() as db:
        query = (
            select(Booking)
            .options(
                selectinload(Booking.driver).selectinload(User.driver_profile),
                selectinload(Booking.vehicle)
            )
            .where(Booking.id == booking_id)
        )
        res = await db.execute(query)
        booking = res.scalars().first()
        if booking:
            snapshot = {
                "booking_id": booking.id,
                "status": booking.status,
                "start_otp": booking.start_otp,
                "pickup_lat": booking.pickup_lat,
                "pickup_lng": booking.pickup_lng,
                "drop_lat": booking.drop_lat,
                "drop_lng": booking.drop_lng,
                "driver": {
                    "id": booking.driver.id,
                    "name": booking.driver.full_name,
                    "phone": booking.driver.phone,
                    "current_lat": booking.driver.driver_profile.current_lat if booking.driver and booking.driver.driver_profile else None,
                    "current_lng": booking.driver.driver_profile.current_lng if booking.driver and booking.driver.driver_profile else None
                } if booking.driver else None
            }

    await ws_manager.connect_trip(booking_id, websocket, snapshot_data=snapshot)

    try:
        while True:
            raw_text = await websocket.receive_text()
            try:
                msg = json.loads(raw_text)
                event = msg.get("event")
                data = msg.get("data", {})

                if event == "PING":
                    await websocket.send_json({"event": "PONG"})
                elif event == "CHAT_MESSAGE":
                    # Save chat message and broadcast
                    sender_id = data.get("sender_id")
                    receiver_id = data.get("receiver_id")
                    text_content = data.get("message")
                    if sender_id and text_content:
                        async with AsyncSessionLocal() as db:
                            cm = ChatMessage(
                                booking_id=booking_id,
                                sender_id=sender_id,
                                receiver_id=receiver_id or sender_id,
                                message=text_content
                            )
                            db.add(cm)
                            await db.commit()

                        await ws_manager.broadcast_to_trip(booking_id, "NEW_CHAT_MESSAGE", {
                            "booking_id": booking_id,
                            "sender_id": sender_id,
                            "message": text_content
                        })
            except Exception as e:
                logger.warning("Error parsing WS client frame: %s", e)
    except WebSocketDisconnect:
        await ws_manager.disconnect_trip(booking_id, websocket)


@router.websocket("/ws/driver/dispatch/{driver_id}")
async def driver_dispatch_websocket(websocket: WebSocket, driver_id: str):
    await ws_manager.connect_user(driver_id, websocket)
    try:
        while True:
            raw_text = await websocket.receive_text()
            try:
                msg = json.loads(raw_text)
                if msg.get("event") == "PING":
                    await websocket.send_json({"event": "PONG"})
            except Exception:
                pass
    except WebSocketDisconnect:
        await ws_manager.disconnect_user(driver_id, websocket)
