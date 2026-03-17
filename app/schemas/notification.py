from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from beanie import PydanticObjectId
from app.models.notification import NotificationType

class NotificationBase(BaseModel):
    title: str
    message: str
    type: NotificationType
    is_read: bool = False

class NotificationCreate(NotificationBase):
    user_id: PydanticObjectId

class NotificationUpdate(BaseModel):
    is_read: Optional[bool] = None

class NotificationOut(NotificationBase):
    id: PydanticObjectId = Field(alias="_id")
    user_id: PydanticObjectId
    created_at: datetime
    is_deleted: bool

    class Config:
        populate_by_name = True
