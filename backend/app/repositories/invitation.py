from typing import List, Optional
from app.models.invitation import Invitation, InvitationStatus
from beanie import PydanticObjectId
from beanie.operators import Or

async def create_invitation(data: dict) -> Invitation:
    """Create a new invitation and return the inserted document."""
    invitation = Invitation(**data)
    return await invitation.insert()

async def get_invitation_by_id(invitation_id: str, fetch_links: bool = False) -> Optional[Invitation]:
    """Return invitation by ID or None if not found."""
    return await Invitation.find_one(Invitation.id == invitation_id, fetch_links=fetch_links)

async def get_user_invitations(user_id: str, status: Optional[InvitationStatus] = None, fetch_links: bool = False) -> List[Invitation]:
    """Return all invitations for a user by ID with optional status filter."""
    # Using Beanie's native Link query syntax for robust matching
    expressions = [Invitation.invitee.id == user_id]
    
    if status:
        expressions.append(Invitation.status == status)
    
    return await Invitation.find(*expressions, fetch_links=fetch_links).to_list()


async def get_invitations_by_email(email: str, status: Optional[InvitationStatus] = None, fetch_links: bool = False) -> List[Invitation]:
    """Return all invitations for a specific email."""
    query = {"invitee_email": email}
    if status:
        query["status"] = status
    return await Invitation.find(query, fetch_links=fetch_links).to_list()


async def get_invitations_by_invitee_id(invitee_id: str, status: Optional[InvitationStatus] = None, fetch_links: bool = False) -> List[Invitation]:
    """Return all invitations for a specific user ID."""
    query = {"invitee.$id": invitee_id}
    if status:
        query["status"] = status
    return await Invitation.find(query, fetch_links=fetch_links).to_list()

async def get_pending_invitation(community_id: str, email: str) -> Optional[Invitation]:
    """
    Return a pending invitation for a community and email if it exists.
    Queries by community ID (DBRef).
    """
    return await Invitation.find_one(
        {"community.$id": community_id},
        {"invitee_email": email},
        {"status": InvitationStatus.PENDING}
    )

async def update_invitation(invitation: Invitation, data: dict) -> Invitation:
    """Update invitation document with provided data."""
    for key, value in data.items():
        if hasattr(invitation, key):
            setattr(invitation, key, value)
    return await invitation.save()
