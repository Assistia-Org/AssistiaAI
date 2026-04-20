from typing import List
from fastapi import HTTPException
from app.core.messages.error_message import (
    COMMUNITY_NOT_FOUND,
    INVITATION_NOT_FOUND,
    INVITATION_ALREADY_EXISTS,
    ALREADY_MEMBER,
    UNAUTHORIZED_INVITATION,
    USER_NOT_FOUND
)
from app.repositories.invitation import (
    create_invitation,
    get_invitation_by_id,
    get_invitations_by_email,
    get_pending_invitation,
    update_invitation
)
from app.repositories.community import get_community_by_id, add_community_member
from app.repositories.user import get_user_by_email, add_community_role
from app.models.invitation import InvitationStatus
from app.models.community import CommunityMember
from app.models.user import CommunityRoleModel, User
from app.schemas.invitation import InvitationCreate, InvitationResponse

async def send_invitation_service(current_user: User, data: InvitationCreate) -> InvitationResponse:
    """
    Send a community invitation.
    Validates community existence, inviter permissions, and existing memberships.
    """
    # 1. Check if community exists
    community = await get_community_by_id(data.community_id)
    if not community:
        raise HTTPException(status_code=404, detail=COMMUNITY_NOT_FOUND)
    
    # 2. Check if inviter is owner (or has permission)
    if community.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail=UNAUTHORIZED_INVITATION)
    
    # 3. Check if invitee is already a member
    is_member = any(m.user_id == str(data.invitee_email) for m in community.members) # Simplified, usually user_id is checked
    # Better: check if user exists first and if their ID is in members
    invitee = await get_user_by_email(data.invitee_email)
    if invitee:
        if any(m.user_id == invitee.id for m in community.members):
            raise HTTPException(status_code=400, detail=ALREADY_MEMBER)
    
    # 4. Check if a pending invitation already exists
    existing_invitation = await get_pending_invitation(data.community_id, data.invitee_email)
    if existing_invitation:
        raise HTTPException(status_code=400, detail=INVITATION_ALREADY_EXISTS)
    
    # 5. Create invitation
    invitation_data = data.model_dump()
    invitation_data["inviter_id"] = current_user.id
    invitation_data["invitee_id"] = invitee.id if invitee else None
    invitation_data["status"] = InvitationStatus.PENDING
    
    invitation = await create_invitation(invitation_data)
    return InvitationResponse.model_validate(invitation)

async def get_my_invitations_service(current_user: User) -> List[InvitationResponse]:
    """Retrieve all invitations for the current user's email or user ID."""
    # Search by email (covers unregistered invitations that become relevant after registration)
    # and by invitee_id (for linked invitations)
    invitations = await get_invitations_by_email(current_user.email)
    
    # If we want to be more specific, we can also search by current_user.id in the repo
    # but since invitations now store both, get_invitations_by_email is still a good starting point.
    # However, to follow the user request strictly, let's ensure we fetch by ID too.
    from app.repositories.invitation import get_invitations_by_invitee_id
    id_invitations = await get_invitations_by_invitee_id(current_user.id)
    
    # Merge and deduplicate
    all_invitations = {str(inv.id): inv for inv in invitations}
    for inv in id_invitations:
        all_invitations[str(inv.id)] = inv
        
    return [InvitationResponse.model_validate(inv) for inv in all_invitations.values()]

async def accept_invitation_service(current_user: User, invitation_id: str) -> InvitationResponse:
    """
    Accept an invitation.
    Updates invitation status and adds user to community.
    """
    invitation = await get_invitation_by_id(invitation_id)
    if not invitation or invitation.invitee_email != current_user.email:
        raise HTTPException(status_code=404, detail=INVITATION_NOT_FOUND)
    
    if invitation.status != InvitationStatus.PENDING:
        raise HTTPException(status_code=400, detail="Invitation is no longer pending.")

    # 1. Update invitation status
    await update_invitation(invitation, {"status": InvitationStatus.ACCEPTED})
    
    # 2. Add member to community
    member = CommunityMember(user=current_user, role=invitation.role)
    await add_community_member(invitation.community_id, member)
    
    # 3. Add community to user
    community = await get_community_by_id(invitation.community_id)
    if community:
        role_data = CommunityRoleModel(
            community_id=community.id,
            role=invitation.role,
            type=community.type
        )
        await add_community_role(current_user.id, role_data)
    
    return InvitationResponse.model_validate(invitation)

async def reject_invitation_service(current_user: User, invitation_id: str) -> InvitationResponse:
    """Reject an invitation."""
    invitation = await get_invitation_by_id(invitation_id)
    if not invitation or invitation.invitee_email != current_user.email:
        raise HTTPException(status_code=404, detail=INVITATION_NOT_FOUND)
    
    if invitation.status != InvitationStatus.PENDING:
        raise HTTPException(status_code=400, detail="Invitation is no longer pending.")
    
    await update_invitation(invitation, {"status": InvitationStatus.REJECTED})
    return InvitationResponse.model_validate(invitation)
