import logging
from typing import Optional
import redis.asyncio as aioredis
from app.core.config import settings

logger = logging.getLogger(__name__)

redis_client: Optional[aioredis.Redis] = None


async def get_redis() -> aioredis.Redis:
    global redis_client
    if redis_client is not None:
        return redis_client

    try:
        # Try real Redis first
        client = aioredis.from_url(
            settings.REDIS_URL,
            decode_responses=True,
            socket_timeout=2.0,
            socket_connect_timeout=2.0
        )
        await client.ping()
        logger.info("Connected to real Redis at %s", settings.REDIS_URL)
        redis_client = client
        return redis_client
    except Exception as e:
        if settings.USE_FAKE_REDIS_FALLBACK:
            logger.warning("Could not connect to Redis at %s (%s). Falling back to FakeRedis in-memory.", settings.REDIS_URL, e)
            import fakeredis.aioredis
            redis_client = fakeredis.aioredis.FakeRedis(decode_responses=True)
            return redis_client
        raise e


async def close_redis() -> None:
    global redis_client
    if redis_client is not None:
        await redis_client.aclose()
        redis_client = None
