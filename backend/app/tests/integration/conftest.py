import asyncio
from typing import AsyncGenerator, Generator
import pytest
import pytest_asyncio
import httpx

# 1. Override settings BEFORE importing FastAPI app to ensure Beanie/Redis uses test databases
from app.core.config import settings
settings.DATABASE_NAME = "test_assistant_ai_integration"
settings.REDIS_URL = "redis://localhost:6379/1"
settings.KAFKA_BOOTSTRAP_SERVERS = ""  # Disable Kafka in integration tests

from app.main import app as fastapi_app
from app.models.user import User
from app.models.community import Community
from app.models.task import Task
from app.models.reservation import Reservation
from app.models.daily_program import DailyProgram
from app.models.invitation import Invitation
from app.models.notification import Notification
from app.core.redis import RedisClient

@pytest.fixture(scope="session")
def event_loop() -> Generator[asyncio.AbstractEventLoop, None, None]:
    """Create and yield an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest_asyncio.fixture(autouse=True)
async def test_app() -> AsyncGenerator[None, None]:
    """Start and stop application database and firebase once per test to ensure event loop alignment."""
    from app.api.dependencies.database import init_db
    from app.core.firebase import init_firebase

    # Explicitly initialize MongoDB via Beanie ODM
    await init_db()
    
    # Explicitly initialize Firebase Admin SDK
    init_firebase()

    yield

    # Close Redis client
    await RedisClient.close()

@pytest_asyncio.fixture(autouse=True)
async def clean_db(test_app: None) -> None:
    """Clear all MongoDB collections and Redis cache before each test to ensure isolation."""
    # Clear MongoDB collections using Beanie models
    models = [
        User,
        Community,
        Task,
        Reservation,
        DailyProgram,
        Invitation,
        Notification
    ]
    for model in models:
        await model.delete_all()

    # Clear Redis database 1
    redis_client = await RedisClient.get_client()
    await redis_client.flushdb()

@pytest_asyncio.fixture
async def async_client() -> AsyncGenerator[httpx.AsyncClient, None]:
    """Yield an HTTPX async client for requesting endpoint routes."""
    transport = httpx.ASGITransport(app=fastapi_app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

@pytest_asyncio.fixture
async def registered_user(async_client: httpx.AsyncClient) -> dict:
    """Create and return a registered user dict for authentication helper."""
    user_data = {
        "username": "integrationtestuser",
        "display_name": "Integration Test User",
        "email": "integrationtest@example.com",
        "password": "SecurePassword123"
    }
    response = await async_client.post("/api/v1/auth/register", json=user_data)
    assert response.status_code == 201
    return user_data

@pytest_asyncio.fixture
async def auth_headers(async_client: httpx.AsyncClient, registered_user: dict) -> dict:
    """Login registered user and return standard Bearer token authorization headers."""
    login_data = {
        "email": registered_user["email"],
        "password": registered_user["password"]
    }
    response = await async_client.post("/api/v1/auth/login", json=login_data)
    assert response.status_code == 200
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}
