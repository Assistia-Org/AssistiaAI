from typing import List, Optional, Union
from pydantic import BaseModel
from app.schemas.base import BaseSchema
from app.schemas.user import UserResponse

class CommunityMemberResponse(BaseModel):
    user: Union[UserResponse, str]
    role: str

    class Config:
        from_attributes = True

class CommunityBase(BaseModel):
    name: str
    type: str

class CommunityCreate(CommunityBase):
    """Schema for creating a community. User must provide a string ID."""
    id: str

class CommunityUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[str] = None
    members: Optional[List[CommunityMemberResponse]] = None

class CommunityResponse(CommunityBase, BaseSchema):
    id: str
    owner_id: str
    members: List[CommunityMemberResponse] = []

    class Config:
        from_attributes = True
        populate_by_name = True
