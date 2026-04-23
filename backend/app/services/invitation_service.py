from typing import List, Optional
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
    get_user_invitations,
    get_pending_invitation,
    update_invitation
)
from app.repositories.community import get_community_by_id, add_community_member
from app.repositories.user import get_user_by_email, add_community_role
from app.models.invitation import InvitationStatus
from app.models.community import CommunityMember
from app.models.user import CommunityRoleModel, User
from app.schemas.invitation import InvitationCreate, InvitationResponse, InvitationFilter


async def send_invitation_service(current_user: User, data: InvitationCreate) -> InvitationResponse:
    """
    Send a community invitation using Beanie Links for rich data.
    """
    # 1. Check if community exists
    community = await get_community_by_id(data.community_id)
    if not community:
        raise HTTPException(status_code=404, detail=COMMUNITY_NOT_FOUND)
    
    # 2. Check if inviter is owner
    if community.owner_id != str(current_user.id):
        raise HTTPException(status_code=403, detail=UNAUTHORIZED_INVITATION)
    
    # 3. Check if invitee exists and is already a member
    invitee = await get_user_by_email(data.invitee_email)
    if not invitee:
        raise HTTPException(status_code=404, detail=USER_NOT_FOUND)
        
    # Comparison with linked user ID
    if any(str(getattr(m.user, "id", m.user)) == str(invitee.id) for m in community.members):
        raise HTTPException(status_code=400, detail=ALREADY_MEMBER)
    
    # 4. Check if pending invitation exists
    existing_invitation = await get_pending_invitation(data.community_id, data.invitee_email)
    if existing_invitation:
        raise HTTPException(status_code=400, detail=INVITATION_ALREADY_EXISTS)
    
    # 5. Create invitation using links
    invitation_data = {
        "community": community,
        "inviter": current_user,
        "invitee": invitee,
        "invitee_email": data.invitee_email,
        "status": InvitationStatus.PENDING,
        "role": data.role
    }
    
    invitation = await create_invitation(invitation_data)
    # Ensure links are fetched for response
    await invitation.fetch_all_links()
    return InvitationResponse.model_validate(invitation)


async def get_my_invitations_service(current_user: User, filter_data: Optional[InvitationFilter] = None) -> List[InvitationResponse]:
    """Retrieve all invitations for the currently logged-in user."""
    status = filter_data.status if filter_data else None
    
    # Single query for user ID using PydanticObjectId
    invitations = await get_user_invitations(
        user_id=str(current_user.id),
        status=status,
        fetch_links=True
    )
    
    return [InvitationResponse.model_validate(inv) for inv in invitations]


async def accept_invitation_service(current_user: User, invitation_id: str) -> InvitationResponse:
    """Accept an invitation and sync community membership."""
    invitation = await get_invitation_by_id(invitation_id, fetch_links=True)
    if not invitation or invitation.invitee_email != current_user.email:
        raise HTTPException(status_code=404, detail=INVITATION_NOT_FOUND)
    
    if invitation.status != InvitationStatus.PENDING:
        raise HTTPException(status_code=400, detail="Invitation is no longer pending.")

    # 1. Update invitation status and link user if not linked
    update_data = {"status": InvitationStatus.ACCEPTED}
    if not invitation.invitee:
        update_data["invitee"] = current_user
        
    await update_invitation(invitation, update_data)
    
    # 2. Add member to community
    member = CommunityMember(user=current_user, role=invitation.role)
    # Get ID from linked community object
    community_id = str(invitation.community.id)
    await add_community_member(community_id, member)
    
    # 3. Add community to user
    community = invitation.community
    role_data = CommunityRoleModel(
        community_id=str(community.id),
        role=invitation.role,
        type=community.type
    )
    await add_community_role(str(current_user.id), role_data)
    
    return InvitationResponse.model_validate(invitation)


async def reject_invitation_service(current_user: User, invitation_id: str) -> InvitationResponse:
    """Reject an invitation."""
    invitation = await get_invitation_by_id(invitation_id, fetch_links=True)
    if not invitation or invitation.invitee_email != current_user.email:
        raise HTTPException(status_code=404, detail=INVITATION_NOT_FOUND)
    
    if invitation.status != InvitationStatus.PENDING:
        raise HTTPException(status_code=400, detail="Invitation is no longer pending.")
    
    await update_invitation(invitation, {"status": InvitationStatus.REJECTED})
    return InvitationResponse.model_validate(invitation)
