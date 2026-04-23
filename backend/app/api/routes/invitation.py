from typing import List, Optional
from fastapi import APIRouter, Depends, status, Body
from app.api.dependencies.auth import get_current_user
from app.models.user import User
from app.schemas.invitation import InvitationCreate, InvitationResponse, InvitationFilter
from app.models.invitation import InvitationStatus
from app.services.invitation_service import (
    accept_invitation_service,
    get_my_invitations_service,
    reject_invitation_service,
    send_invitation_service,
)
from app.core.messages.success_message import (
    INVITATION_SENT,
    INVITATION_ACCEPTED,
    INVITATION_REJECTED,
)

router = APIRouter(prefix="/invitations", tags=["invitations"])

@router.post("/", response_model=InvitationResponse, status_code=status.HTTP_201_CREATED)
async def send_invitation(
    data: InvitationCreate,
    current_user: User = Depends(get_current_user)
) -> InvitationResponse:
    """Send a community invitation to an email."""
    return await send_invitation_service(current_user, data)

@router.get("/me", response_model=List[InvitationResponse], status_code=status.HTTP_200_OK)
async def get_my_invitations(
    status: Optional[InvitationStatus] = None,
    current_user: User = Depends(get_current_user)
) -> List[InvitationResponse]:
    """Get all invitations for the logged-in user."""
    filter_data = InvitationFilter(status=status) if status else None
    return await get_my_invitations_service(current_user, filter_data)

@router.patch("/{invitation_id}/accept", response_model=InvitationResponse, status_code=status.HTTP_200_OK)
async def accept_invitation(
    invitation_id: str,
    current_user: User = Depends(get_current_user)
) -> InvitationResponse:
    """Accept a pending community invitation."""
    return await accept_invitation_service(current_user, invitation_id)

@router.patch("/{invitation_id}/reject", response_model=InvitationResponse, status_code=status.HTTP_200_OK)
async def reject_invitation(
    invitation_id: str,
    current_user: User = Depends(get_current_user)
) -> InvitationResponse:
    """Reject a pending community invitation."""
    return await reject_invitation_service(current_user, invitation_id)
