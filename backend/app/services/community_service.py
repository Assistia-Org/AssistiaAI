from fastapi import HTTPException
from app.core.messages.error_message import COMMUNITY_NOT_FOUND, COMMUNITY_ALREADY_EXISTS
from app.repositories.community import (
    create_community,
    get_community_by_id,
    list_communities,
    update_community,
    delete_community,
)
from app.schemas.community import CommunityCreate, CommunityUpdate, CommunityResponse


async def create_community_service(data: CommunityCreate) -> CommunityResponse:
    """Orchestrate community creation."""
    existing = await get_community_by_id(data.id)
    if existing:
        raise HTTPException(status_code=400, detail=COMMUNITY_ALREADY_EXISTS)
    
    community = await create_community(data.model_dump(by_alias=True))
    full_community = await get_community_by_id(community.id, fetch_links=True)
    return CommunityResponse.model_validate(full_community)


async def get_community_service(community_id: str) -> CommunityResponse:
    """Orchestrate community retrieval."""
    community = await get_community_by_id(community_id, fetch_links=True)
    if not community:
        raise HTTPException(status_code=404, detail=COMMUNITY_NOT_FOUND)
    return CommunityResponse.model_validate(community)


async def list_communities_service() -> list[CommunityResponse]:
    """Orchestrate listing all communities."""
    communities = await list_communities()
    return [CommunityResponse.model_validate(c) for c in communities]


async def update_community_service(community_id: str, data: CommunityUpdate) -> CommunityResponse:
    """Orchestrate community update."""
    community = await get_community_by_id(community_id)
    if not community:
        raise HTTPException(status_code=404, detail=COMMUNITY_NOT_FOUND)
    
    updated_community = await update_community(community, data.model_dump(exclude_unset=True))
    # Fetch links for the response
    full_community = await get_community_by_id(updated_community.id, fetch_links=True)
    return CommunityResponse.model_validate(full_community)


async def delete_community_service(community_id: str) -> None:
    """Orchestrate community deletion."""
    community = await get_community_by_id(community_id)
    if not community:
        raise HTTPException(status_code=404, detail=COMMUNITY_NOT_FOUND)
    await delete_community(community)
