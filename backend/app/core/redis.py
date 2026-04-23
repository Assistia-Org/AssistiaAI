import redis.asyncio as redis
from app.core.config import settings

class RedisClient:
    """
    Singleton Redis client for the application.
    """
    _client: redis.Redis = None

    @classmethod
    async def get_client(cls) -> redis.Redis:
        if cls._client is None:
            cls._client = redis.from_url(
                settings.REDIS_URL,
                encoding="utf-8",
                decode_responses=True
            )
        return cls._client

    @classmethod
    async def close(cls):
        if cls._client:
            await cls._client.close()
            cls._client = None

# Helper functions for common operations
async def set_redis_value(key: str, value: str, expire: int = None):
    client = await RedisClient.get_client()
    await client.set(key, value, ex=expire)

async def get_redis_value(key: str) -> str:
    client = await RedisClient.get_client()
    return await client.get(key)

async def delete_redis_value(key: str):
    client = await RedisClient.get_client()
    await client.delete(key)

async def increment_redis_value(key: str, expire: int = None) -> int:
    client = await RedisClient.get_client()
    val = await client.incr(key)
    if expire and val == 1:
        await client.expire(key, expire)
    return val
