from typing import List
from datetime import datetime, timezone
from pydantic import BaseModel, Field
from beanie import Document

class CommunityMember(BaseModel):
    user_id: str
    role: str

class Community(Document):
    id: str = Field(alias="_id")
    name: str
    type: str
    owner_id: str
    members: List[CommunityMember] = Field(default_factory=list)
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    class Settings:
        name = "communities"
