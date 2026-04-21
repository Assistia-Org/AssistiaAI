from fastapi import APIRouter, status, Depends
from app.schemas.community import CommunityCreate, CommunityUpdate, CommunityResponse
from app.services.community_service import (
    create_community_service,
    delete_community_service,
    get_community_service,
    list_communities_service,
    update_community_service,
    get_my_communities_service,
)
from app.api.dependencies.auth import get_current_user
from app.models.user import User

router = APIRouter(prefix="/communities", tags=["communities"])


@router.post("/", response_model=CommunityResponse, status_code=status.HTTP_201_CREATED)
async def create_community(
    data: CommunityCreate, 
    current_user: User = Depends(get_current_user)
) -> CommunityResponse:
    """Create a new community."""
    return await create_community_service(data, current_user)


@router.get("/me", response_model=list[CommunityResponse], status_code=status.HTTP_200_OK)
async def get_my_communities(
    current_user: User = Depends(get_current_user)
) -> list[CommunityResponse]:
    """Get all communities the current user is a member or owner of."""
    return await get_my_communities_service(current_user.id)


@router.get("/{community_id}", response_model=CommunityResponse, status_code=status.HTTP_200_OK)
async def get_community(
    community_id: str, 
    current_user: User = Depends(get_current_user)
) -> CommunityResponse:
    """Get community details by ID."""
    return await get_community_service(community_id)


@router.get("/", response_model=list[CommunityResponse], status_code=status.HTTP_200_OK)
async def list_communities(
    current_user: User = Depends(get_current_user)
) -> list[CommunityResponse]:
    """List all communities."""
    return await list_communities_service()


@router.patch("/{community_id}", response_model=CommunityResponse, status_code=status.HTTP_200_OK)
async def update_community(
    community_id: str, 
    data: CommunityUpdate, 
    current_user: User = Depends(get_current_user)
) -> CommunityResponse:
    """Update community details. Only owner is authorized."""
    return await update_community_service(community_id, data, current_user)


@router.delete("/{community_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_community(
    community_id: str, 
    current_user: User = Depends(get_current_user)
) -> None:
    """Delete a community. Only owner is authorized."""
    await delete_community_service(community_id, current_user)
