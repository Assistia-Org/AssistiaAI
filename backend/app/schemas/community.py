from typing import List, Optional
from pydantic import BaseModel
from app.models.community import CommunityMember
from app.schemas.base import BaseSchema

class CommunityBase(BaseModel):
    name: str
    type: str
    owner_id: str
    members: List[CommunityMember] = []

class CommunityCreate(CommunityBase):
    id: str

class CommunityUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[str] = None
    members: Optional[List[CommunityMember]] = None

class CommunityResponse(CommunityBase, BaseSchema):
    id: str

    class Config:
        from_attributes = True
        populate_by_name = True
