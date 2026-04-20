from enum import Enum
from typing import Optional, List
from pydantic import Field
from beanie import PydanticObjectId
from app.models.base import BaseDocument

class InvitationStatus(str, Enum):
    """Enumeration for invitation statuses."""
    PENDING = "pending"
    ACCEPTED = "accepted"
    REJECTED = "rejected"

class Invitation(BaseDocument):
    """
    Model representing a community invitation.
    Stored in the 'invitations' collection.
    """
    id: Optional[PydanticObjectId] = Field(default=None, alias="_id")
    community_id: str
    inviter_id: str
    invitee_email: str
    invitee_id: Optional[str] = None
    status: InvitationStatus = InvitationStatus.PENDING
    role: str = "member"

    class Settings:
        name = "invitations"
