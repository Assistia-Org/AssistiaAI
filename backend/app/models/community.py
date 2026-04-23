from typing import List, Optional
from pydantic import BaseModel, Field
from beanie import Link
from app.models.base import BaseDocument
from app.models.user import User
from uuid import uuid4

class CommunityMember(BaseModel):
    user: Link[User]
    role: str

class Community(BaseDocument):
    id: str = Field(default_factory=lambda: uuid4().hex, alias="_id")
    name: str
    type: str
    owner_id: str
    members: List[CommunityMember] = Field(default_factory=list)

    class Settings:
        name = "communities"
