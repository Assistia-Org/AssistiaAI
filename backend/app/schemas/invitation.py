from datetime import datetime
from typing import Optional, Union
from pydantic import BaseModel, Field, EmailStr
from beanie import PydanticObjectId
from app.models.invitation import InvitationStatus
from app.schemas.community import CommunityResponse
from app.schemas.user import UserResponse

class InvitationCreate(BaseModel):
    """Schema for creating a new invitation."""
    community_id: str
    invitee_email: EmailStr
    role: str = "member"

class InvitationResponse(BaseModel):
    """
    Schema for returning invitation data.
    Provides full community and inviter details if available.
    """
    id: str = Field(alias="_id")
    community: Union[CommunityResponse, str]
    inviter: Union[UserResponse, str]
    invitee_email: EmailStr
    invitee: Optional[Union[UserResponse, str]] = None
    status: InvitationStatus
    role: str
    created_at: datetime

    class Config:
        from_attributes = True
        populate_by_name = True

class InvitationStatusUpdate(BaseModel):
    """Schema for updating invitation status."""
    status: InvitationStatus
