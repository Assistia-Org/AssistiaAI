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
    description: Optional[str] = None

class CommunityCreate(CommunityBase):
    """Schema for creating a community."""
    pass

class CommunityUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[str] = None
    description: Optional[str] = None
    members: Optional[List[CommunityMemberResponse]] = None

class CommunityResponse(CommunityBase, BaseSchema):
    id: str
    owner_id: str
    members: List[CommunityMemberResponse] = []
    description: Optional[str] = None

    class Config:
        from_attributes = True
        populate_by_name = True
