from typing import List, Optional
from pydantic import BaseModel, EmailStr
from app.models.user import CommunityRoleModel, PersonalSettingsModel
from app.schemas.base import BaseSchema

class UserBase(BaseModel):
    username: str
    display_name: str
    email: EmailStr
    avatar_url: Optional[str] = None
    joined_communities: List[CommunityRoleModel] = []
    personal_settings: Optional[PersonalSettingsModel] = None

class UserCreate(UserBase):
    password: str
    verification_code: str

class UserUpdate(BaseModel):
    username: Optional[str] = None
    display_name: Optional[str] = None
    email: Optional[EmailStr] = None
    avatar_url: Optional[str] = None
    personal_settings: Optional[PersonalSettingsModel] = None

class UserResponse(UserBase, BaseSchema):
    id: str

    class Config:
        from_attributes = True
        populate_by_name = True
