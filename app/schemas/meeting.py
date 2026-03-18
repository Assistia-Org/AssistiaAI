from pydantic import BaseModel, Field, HttpUrl
from typing import Optional, List
from datetime import datetime
from beanie import PydanticObjectId
from app.models.meeting import MeetingPlatform

class MeetingBase(BaseModel):
    title: str
    participants: List[str] = Field(default_factory=list)
    platform: MeetingPlatform
    meeting_link: Optional[HttpUrl] = None
    start_time: datetime
    end_time: datetime
    agenda: Optional[str] = None

class MeetingCreate(MeetingBase):
    user_id: PydanticObjectId

class MeetingUpdate(BaseModel):
    title: Optional[str] = None
    participants: Optional[List[str]] = None
    platform: Optional[MeetingPlatform] = None
    meeting_link: Optional[HttpUrl] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    agenda: Optional[str] = None

class MeetingOut(MeetingBase):
    id: PydanticObjectId = Field(alias="_id")
    user_id: PydanticObjectId
    is_deleted: bool

    class Config:
        populate_by_name = True
