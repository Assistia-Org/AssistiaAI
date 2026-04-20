from typing import List, Optional
from pydantic import BaseModel, Field
from beanie import Link
from app.models.base import BaseDocument
from app.models.user import User

class CommunityMember(BaseModel):
    user: Link[User]
    role: str

class Community(BaseDocument):
    id: str = Field(alias="_id")
    name: str
    type: str
    owner_id: str
    members: List[CommunityMember] = Field(default_factory=list)

    class Settings:
        name = "communities"
