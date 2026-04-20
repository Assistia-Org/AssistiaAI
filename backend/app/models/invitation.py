from enum import Enum
from typing import Optional
from uuid import uuid4
from pydantic import Field
from beanie import Link
from app.models.base import BaseDocument
from app.models.community import Community
from app.models.user import User

class InvitationStatus(str, Enum):
    """Enumeration for invitation statuses."""
    PENDING = "pending"
    ACCEPTED = "accepted"
    REJECTED = "rejected"

class Invitation(BaseDocument):
    """
    Model representing a community invitation.
    Stored in the 'invitations' collection.
    Uses Beanie Links for rich relations.
    ID is stored as a string.
    """
    id: str = Field(default_factory=lambda: uuid4().hex, alias="_id")
    community: Link[Community]
    inviter: Link[User]
    invitee_email: str
    invitee: Optional[Link[User]] = None
    status: InvitationStatus = InvitationStatus.PENDING
    role: str = "member"

    class Settings:
        name = "invitations"
