import asyncio
import json
import logging
from typing import Dict, Set, Optional
from fastapi import WebSocket
from app.core.redis import get_redis

logger = logging.getLogger(__name__)


class WebSocketManager:
    def __init__(self):
        # booking_id -> Set of WebSockets
        self.active_trip_connections: Dict[str, Set[WebSocket]] = {}
        # user_id -> Set of WebSockets (e.g. driver dispatch)
        self.active_user_connections: Dict[str, Set[WebSocket]] = {}
        # booking_id -> Redis pubsub background task
        self.pubsub_tasks: Dict[str, asyncio.Task] = {}

    async def connect_trip(self, booking_id: str, websocket: WebSocket, snapshot_data: Optional[dict] = None) -> None:
        await websocket.accept()
        if booking_id not in self.active_trip_connections:
            self.active_trip_connections[booking_id] = set()
            # Start background Redis pub/sub listener for this booking if not running
            self.pubsub_tasks[booking_id] = asyncio.create_task(self._listen_redis_channel(booking_id))

        self.active_trip_connections[booking_id].add(websocket)

        # Immediate snapshot-on-connect
        if snapshot_data:
            await websocket.send_json({
                "event": "HYDRATION_SNAPSHOT",
                "data": snapshot_data
            })

    async def disconnect_trip(self, booking_id: str, websocket: WebSocket) -> None:
        if booking_id in self.active_trip_connections:
            self.active_trip_connections[booking_id].discard(websocket)
            if not self.active_trip_connections[booking_id]:
                del self.active_trip_connections[booking_id]
                # Cancel Redis pubsub task
                task = self.pubsub_tasks.pop(booking_id, None)
                if task:
                    task.cancel()

    async def connect_user(self, user_id: str, websocket: WebSocket) -> None:
        await websocket.accept()
        if user_id not in self.active_user_connections:
            self.active_user_connections[user_id] = set()
        self.active_user_connections[user_id].add(websocket)

    async def disconnect_user(self, user_id: str, websocket: WebSocket) -> None:
        if user_id in self.active_user_connections:
            self.active_user_connections[user_id].discard(websocket)
            if not self.active_user_connections[user_id]:
                del self.active_user_connections[user_id]

    async def broadcast_to_trip(self, booking_id: str, event: str, data: dict) -> None:
        """Broadcasts event directly to local sockets AND publishes to Redis pub/sub."""
        message = json.dumps({"event": event, "data": data})
        # Publish to Redis
        redis = await get_redis()
        channel = f"channel:trip:{booking_id}"
        await redis.publish(channel, message)

        # Also push directly to local connections
        connections = self.active_trip_connections.get(booking_id, set()).copy()
        for ws in connections:
            try:
                await ws.send_text(message)
            except Exception as e:
                logger.warning("Error sending WS message: %s", e)
                await self.disconnect_trip(booking_id, ws)

    async def _listen_redis_channel(self, booking_id: str) -> None:
        redis = await get_redis()
        pubsub = redis.pubsub()
        channel = f"channel:trip:{booking_id}"
        await pubsub.subscribe(channel)
        try:
            async for message in pubsub.listen():
                if message and message.get("type") == "message":
                    payload = message.get("data")
                    connections = self.active_trip_connections.get(booking_id, set()).copy()
                    for ws in connections:
                        try:
                            await ws.send_text(payload)
                        except Exception:
                            pass
        except asyncio.CancelledError:
            await pubsub.unsubscribe(channel)
            await pubsub.close()
        except Exception as e:
            logger.error("Redis pubsub listener error for %s: %s", booking_id, e)


ws_manager = WebSocketManager()
