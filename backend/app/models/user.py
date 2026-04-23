from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field, EmailStr
from app.models.base import BaseDocument
from uuid import uuid4

class CommunityRoleModel(BaseModel):
    community_id: str
    role: str
    type: str

class PersonalSettingsModel(BaseModel):
    theme: str = "light"
    notifications: bool = True
    language: str = "tr"

class User(BaseDocument):
    id: str = Field(default_factory=lambda: uuid4().hex, alias="_id")
    username: str
    display_name: str
    email: EmailStr
    hashed_password: str
    is_active: bool = True
    avatar_url: Optional[str] = None
    joined_communities: List[CommunityRoleModel] = Field(default_factory=list)
    personal_settings: PersonalSettingsModel = Field(default_factory=PersonalSettingsModel)
    reset_token: Optional[str] = None
    reset_token_expires_at: Optional[datetime] = None

    class Settings:
        name = "users"
