from enum import Enum
from typing import Any, Optional
from uuid import uuid4
from pydantic import Field
from app.models.base import BaseDocument


class NotificationType(str, Enum):
    """Enumeration for notification types."""

    INVITATION = "invitation"
    INVITATION_ACCEPTED = "invitation_accepted"
    INVITATION_REJECTED = "invitation_rejected"
    GENERAL = "general"


class Notification(BaseDocument):
    """
    Model representing a persistent in-app notification.
    Stored in the 'notifications' collection.
    Each notification belongs to a single user (user_id).
    """

    id: str = Field(default_factory=lambda: uuid4().hex, alias="_id")
    user_id: str
    type: NotificationType
    title: str
    body: str
    is_read: bool = False
    metadata: Optional[dict[str, Any]] = None

    class Settings:
        name = "notifications"
