from beanie import Document, PydanticObjectId
from pydantic import Field
from typing import Optional
from datetime import datetime
from enum import Enum
from .base import SoftDeleteMixin

class IntegrationService(str, Enum):
    google_calendar = "google_calendar"
    zoom = "zoom"

class Integration(Document, SoftDeleteMixin):
    user_id: PydanticObjectId
    service: IntegrationService
    access_token: str
    refresh_token: Optional[str] = None
    expires_at: Optional[datetime] = None
    connected_at: datetime = Field(default_factory=datetime.utcnow)

    class Settings:
        name = "integrations"
