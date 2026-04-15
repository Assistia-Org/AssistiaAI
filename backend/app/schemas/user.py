from typing import List, Optional
from pydantic import BaseModel, EmailStr
from app.models.user import CommunityRoleModel, PersonalSettingsModel

class UserBase(BaseModel):
    username: str
    display_name: str
    email: EmailStr
    avatar_url: Optional[str] = None
    joined_communities: List[CommunityRoleModel] = []
    personal_settings: Optional[PersonalSettingsModel] = None

class UserCreate(UserBase):
    id: str
    password: str

class UserUpdate(BaseModel):
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    personal_settings: Optional[PersonalSettingsModel] = None

class UserResponse(UserBase):
    id: str

    class Config:
        from_attributes = True
        populate_by_name = True
