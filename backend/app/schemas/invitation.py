from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, EmailStr
from beanie import PydanticObjectId
from app.models.invitation import InvitationStatus

class InvitationCreate(BaseModel):
    """Schema for creating a new invitation."""
    community_id: str
    invitee_email: EmailStr
    role: str = "member"

class InvitationResponse(BaseModel):
    """Schema for returning invitation data."""
    id: PydanticObjectId = Field(alias="_id")
    community_id: str
    inviter_id: str
    invitee_email: EmailStr
    invitee_id: Optional[str] = None
    status: InvitationStatus
    role: str
    created_at: datetime

    class Config:
        from_attributes = True
        populate_by_name = True

class InvitationStatusUpdate(BaseModel):
    """Schema for updating invitation status."""
    status: InvitationStatus
