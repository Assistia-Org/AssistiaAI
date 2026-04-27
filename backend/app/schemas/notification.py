from datetime import datetime
from typing import Any, List, Optional
from pydantic import BaseModel, Field
from app.models.notification import NotificationType


class NotificationResponse(BaseModel):
    """Schema for returning a single notification."""

    id: str = Field(alias="_id")
    user_id: str
    type: NotificationType
    title: str
    body: str
    is_read: bool
    metadata: Optional[dict[str, Any]] = None
    created_at: datetime

    class Config:
        from_attributes = True
        populate_by_name = True


class NotificationListResponse(BaseModel):
    """Schema for returning a paginated list of notifications with unread count."""

    notifications: List[NotificationResponse]
    unread_count: int
