from motor.motor_asyncio import AsyncIOMotorClient
from beanie import init_beanie
from app.core.config import settings
from app.models.user import User
from app.models.community import Community
from app.models.task import Task
from app.models.reservation import Reservation
from app.models.daily_program import DailyProgram
from app.models.invitation import Invitation

async def init_db():
    """Initialize Beanie ODM with MongoDB."""
    # Invitation.model_rebuild()
    # Community.model_rebuild()
    client = AsyncIOMotorClient(settings.MONGODB_URL)
    await init_beanie(
        database=client.get_database(settings.DATABASE_NAME),
        document_models=[
            User,
            Community,
            Task,
            Reservation,
            DailyProgram,
            Invitation,
        ]
    )
