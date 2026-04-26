from fastapi import HTTPException
from app.core.messages.error_message import (
    COMMUNITY_NOT_FOUND, 
    COMMUNITY_ALREADY_EXISTS,
    UNAUTHORIZED_COMMUNITY_ACTION,
    MEMBER_NOT_FOUND,
    CANNOT_REMOVE_SELF,
    OWNER_CANNOT_LEAVE
)
from app.core.messages.success_message import MEMBER_REMOVED, COMMUNITY_LEFT
from app.repositories.community import (
    create_community,
    get_community_by_id,
    list_communities,
    update_community,
    delete_community,
    get_my_communities,
    remove_community_member,
)
from app.repositories.user import remove_community_role
from app.schemas.community import CommunityCreate, CommunityUpdate, CommunityResponse
from app.models.user import User
from app.models.community import CommunityMember


async def create_community_service(data: CommunityCreate, current_user: User) -> CommunityResponse:
    """
    Orchestrate community creation.
    Automatically assigns owner_id and adds creator as the first member.
    """

    community_dict = data.model_dump(by_alias=True)
    
    # Automate ownership and membership
    community_dict["owner_id"] = str(current_user.id)
    
    # Initialize members list with the owner
    owner_member = CommunityMember(user=current_user, role="owner")
    community_dict["members"] = [owner_member]
    
    community = await create_community(community_dict)
    
    # Fetch links for the response
    await community.fetch_all_links()
    return CommunityResponse.model_validate(community)


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


async def get_my_communities_service(user_id: str) -> list[CommunityResponse]:
    """Orchestrate retrieval of user's communities."""
    communities = await get_my_communities(user_id, fetch_links=True)
    return [CommunityResponse.model_validate(c) for c in communities]


async def update_community_service(community_id: str, data: CommunityUpdate, current_user: User) -> CommunityResponse:
    """Orchestrate community update. Only owner is authorized."""
    community = await get_community_by_id(community_id)
    if not community:
        raise HTTPException(status_code=404, detail=COMMUNITY_NOT_FOUND)
    
    # Ownership check
    if community.owner_id != str(current_user.id):
        raise HTTPException(status_code=403, detail=UNAUTHORIZED_COMMUNITY_ACTION)
    
    updated_community = await update_community(community, data.model_dump(exclude_unset=True))
    # Fetch links for the response
    await updated_community.fetch_all_links()
    return CommunityResponse.model_validate(updated_community)


async def delete_community_service(community_id: str, current_user: User) -> None:
    """Orchestrate community deletion. Only owner is authorized."""
    community = await get_community_by_id(community_id)
    if not community:
        raise HTTPException(status_code=404, detail=COMMUNITY_NOT_FOUND)
    
    # Ownership check
    if community.owner_id != str(current_user.id):
        raise HTTPException(status_code=403, detail=UNAUTHORIZED_COMMUNITY_ACTION)
        
    
    await delete_community(community)


async def remove_community_member_service(community_id: str, user_id: str, current_user: User) -> str:
    """
    Orchestrate member removal from a community.
    Only the owner is authorized to remove members.
    The owner cannot remove themselves.
    """
    community = await get_community_by_id(community_id)
    if not community:
        raise HTTPException(status_code=404, detail=COMMUNITY_NOT_FOUND)
    
    # Ownership check
    if community.owner_id != str(current_user.id):
        raise HTTPException(status_code=403, detail=UNAUTHORIZED_COMMUNITY_ACTION)
    
    # Self-removal check
    if user_id == str(current_user.id):
        raise HTTPException(status_code=400, detail=CANNOT_REMOVE_SELF)
    
    # Remove from community
    removed = await remove_community_member(community_id, user_id)
    if not removed:
        raise HTTPException(status_code=404, detail=MEMBER_NOT_FOUND)
    
    # Remove from user's joined list (consistency)
    await remove_community_role(user_id, community_id)
    
    return MEMBER_REMOVED


async def leave_community_service(community_id: str, current_user: User) -> str:
    """
    Orchestrate leaving a community.
    The owner cannot leave.
    """
    community = await get_community_by_id(community_id)
    if not community:
        raise HTTPException(status_code=404, detail=COMMUNITY_NOT_FOUND)
    
    # Owner check
    if community.owner_id == str(current_user.id):
        raise HTTPException(status_code=400, detail=OWNER_CANNOT_LEAVE)
    
    # Remove from community
    removed = await remove_community_member(community_id, str(current_user.id))
    if not removed:
        raise HTTPException(status_code=404, detail=MEMBER_NOT_FOUND)
    
    # Remove from user's joined list
    await remove_community_role(str(current_user.id), community_id)
    
    return COMMUNITY_LEFT
