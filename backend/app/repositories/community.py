from typing import List, Optional
from app.models.community import Community, CommunityMember

async def create_community(community_data: dict) -> Community:
    """Create a new community and return the inserted document."""
    community = Community(**community_data)
    return await community.insert()

async def get_community_by_id(community_id: str, fetch_links: bool = False) -> Optional[Community]:
    """Return community by ID or None if not found."""
    return await Community.find_one(Community.id == community_id, fetch_links=fetch_links)

async def list_communities() -> List[Community]:
    """Return all communities."""
    return await Community.find_all().to_list()

async def add_community_member(community_id: str, member: CommunityMember) -> bool:
    """Add a member to a community."""
    community = await get_community_by_id(community_id)
    if not community:
        return False
    community.members.append(member)
    await community.save()
    return True

async def remove_community_member(community_id: str, user_id: str) -> bool:
    """Remove a member from a community by user ID."""
    community = await get_community_by_id(community_id)
    if not community:
        return False
    # Handle linked user ID check
    community.members = [
        m for m in community.members 
        if str(getattr(m.user, "id", m.user)) != user_id
    ]
    await community.save()
    return True

async def update_community(community: Community, data: dict) -> Community:
    """Update community document with provided data."""
    for key, value in data.items():
        if hasattr(community, key):
            setattr(community, key, value)
    return await community.save()

async def delete_community(community: Community) -> bool:
    """Delete a community document."""
    await community.delete()
    return True

async def get_my_communities(user_id: str) -> list[Community]:
        try:
            obj_id = PydanticObjectId(user_id)
        except Exception:
            return []

        return await Community.find(
            Community.user_id == obj_id,
            Community.is_deleted == False
        ).to_list()