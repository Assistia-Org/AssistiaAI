from beanie import Document, PydanticObjectId
from pydantic import Field, HttpUrl
from typing import Optional, List
from datetime import datetime
from enum import Enum
from .base import SoftDeleteMixin

class MeetingPlatform(str, Enum):
    zoom = "Zoom"
    google_meet = "Google Meet"
    teams = "Teams"

class Meeting(Document, SoftDeleteMixin):
    user_id: PydanticObjectId
    title: str
    participants: List[str] = Field(default_factory=list)
    platform: MeetingPlatform
    meeting_link: Optional[HttpUrl] = None
    start_time: datetime
    end_time: datetime
    agenda: Optional[str] = None

    class Settings:
        name = "meetings"
