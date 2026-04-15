from typing import List
from pydantic import BaseModel, Field
from app.models.base import BaseDocument

class CommunityMember(BaseModel):
    user_id: str
    role: str

class Community(BaseDocument):
    id: str = Field(alias="_id")
    name: str
    type: str
    owner_id: str
    members: List[CommunityMember] = Field(default_factory=list)

    class Settings:
        name = "communities"
