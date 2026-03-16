from beanie import Document, PydanticObjectId
from pydantic import Field
from typing import Optional
from datetime import datetime
from enum import Enum
from .base import SoftDeleteMixin

class NotificationType(str, Enum):
    meeting = "meeting"
    trip = "trip"
    task = "task"
    system = "system"

class Notification(Document, SoftDeleteMixin):
    user_id: PydanticObjectId
    title: str
    message: str
    type: NotificationType
    is_read: bool = False
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Settings:
        name = "notifications"
