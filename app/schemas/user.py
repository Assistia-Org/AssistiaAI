from beanie import PydanticObjectId
from pydantic import BaseModel, EmailStr, ConfigDict, Field
from datetime import datetime
from typing import Annotated
from pydantic import BeforeValidator

PyObjectId = Annotated[str, BeforeValidator(str)]


class UserBase(BaseModel):
    full_name: str
    email: EmailStr
    is_active: bool = True


class UserCreate(UserBase):
    password: str


class UserUpdate(BaseModel):
    full_name: str | None = None
    email: EmailStr | None = None
    password: str | None = None
    is_active: bool | None = None


class UserResponse(UserBase):
    id: PyObjectId = Field(alias="_id")
    is_superuser: bool
    created_at: datetime

    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True,
    )
