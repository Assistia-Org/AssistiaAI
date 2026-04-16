from fastapi import APIRouter, status, Depends
from backend.app.schemas.community import CommunityCreate, CommunityUpdate, CommunityResponse
from backend.app.services.community_service import (
    create_community_service,
    delete_community_service,
    get_community_service,
    list_communities_service,
    update_community_service,
)

router = APIRouter(prefix="/communities", tags=["communities"])


@router.post("/", response_model=CommunityResponse, status_code=status.HTTP_201_CREATED)
async def create_community(data: CommunityCreate) -> CommunityResponse:
    """Create a new community."""
    return await create_community_service(data)


@router.get("/{community_id}", response_model=CommunityResponse, status_code=status.HTTP_200_OK)
async def get_community(community_id: str) -> CommunityResponse:
    """Get community details by ID."""
    return await get_community_service(community_id)


@router.get("/", response_model=list[CommunityResponse], status_code=status.HTTP_200_OK)
async def list_communities() -> list[CommunityResponse]:
    """List all communities."""
    return await list_communities_service()


@router.patch("/{community_id}", response_model=CommunityResponse, status_code=status.HTTP_200_OK)
async def update_community(community_id: str, data: CommunityUpdate) -> CommunityResponse:
    """Update community details."""
    return await update_community_service(community_id, data)


@router.delete("/{community_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_community(community_id: str) -> None:
    """Delete a community."""
    await delete_community_service(community_id)
