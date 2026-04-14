from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime
from beanie import PydanticObjectId

class UserBase(BaseModel):
    full_name: str
    email: EmailStr
    timezone: Optional[str] = "Europe/Istanbul"
    language: Optional[str] = "Turkish"
    subscription_plan: Optional[str] = "Free"

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    email: Optional[EmailStr] = None
    timezone: Optional[str] = None
    language: Optional[str] = None
    subscription_plan: Optional[str] = None
    password: Optional[str] = None

class UserOut(UserBase):
    id: PydanticObjectId = Field(alias="_id")
    created_at: datetime
    is_deleted: bool

    class Config:
        populate_by_name = True
