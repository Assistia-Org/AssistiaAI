from typing import List, Optional
from pydantic import BaseModel, Field, EmailStr
from beanie import Document

class CommunityRoleModel(BaseModel):
    community_id: str
    role: str
    type: str

class PersonalSettingsModel(BaseModel):
    theme: str = "light"
    notifications: bool = True
    language: str = "tr"

class User(Document):
    id: str = Field(alias="_id")
    username: str
    display_name: str
    email: EmailStr
    avatar_url: Optional[str] = None
    joined_communities: List[CommunityRoleModel] = Field(default_factory=list)
    personal_settings: PersonalSettingsModel = Field(default_factory=PersonalSettingsModel)

    class Settings:
        name = "users"
