import logging
from redis import asyncio as aioredis
from app.core.config import settings

logger = logging.getLogger("nutritrack.redis")

# Global Redis client
redis_client: aioredis.Redis = None

async def init_redis() -> aioredis.Redis:
    """Initialize Redis client and verify connection."""
    global redis_client
    try:
        redis_client = aioredis.from_url(
            settings.REDIS_URL,
            decode_responses=True,
            socket_timeout=5.0
        )
        await redis_client.ping()
        logger.info("Successfully connected to Redis.")
        return redis_client
    except Exception as e:
        logger.error(f"Redis connection failed: {e}. AI integrations and caching might be degraded.")
        redis_client = None
        return None

async def close_redis() -> None:
    """Close Redis client connection."""
    global redis_client
    if redis_client:
        await redis_client.close()
        logger.info("Redis connection closed.")

def get_redis() -> aioredis.Redis:
    """Dependency injection getter for Redis client."""
    return redis_client
