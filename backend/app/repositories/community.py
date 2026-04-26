from typing import List, Optional
from beanie import PydanticObjectId
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
    """Remove a member from a community by user ID. Returns True if member was removed."""
    community = await get_community_by_id(community_id)
    if not community:
        return False
    
    initial_count = len(community.members)
    # Handle linked user ID check
    community.members = [
        m for m in community.members 
        if str(getattr(m.user, "id", m.user)) != user_id
    ]
    
    if len(community.members) == initial_count:
        return False
        
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

async def get_my_communities(user_id: str, fetch_links: bool = False) -> List[Community]:
    """
    Return communities where user is owner or member.
    Uses an exhaustive search strategy for nested links in the members array.
    """
    try:
        obj_id = PydanticObjectId(user_id)
    except Exception:
        obj_id = None

    ids_to_check = [user_id]
    if obj_id:
        ids_to_check.append(obj_id)
    
    or_filters = []
    for uid in ids_to_check:
        # 1. Direct ownership
        or_filters.append({"owner_id": uid})
        
        # 2. Check within the 'members' array for the 'user' field in all known formats
        # We check both direct path and $elemMatch path for robustness
        or_filters.extend([
            {"members.user": uid},
            {"members.user.$id": uid},
            {"members.user.id": uid},
            {"members.user._id": uid}
        ])
        
        # $elemMatch patterns (keys are relative to array element)
        patterns = [
            {"user": uid},                  # Direct match
            {"user.$id": uid},              # DBRef match
            {"user.id": uid},               # Embedded object 'id'
            {"user._id": uid},              # Embedded object '_id'
            {"user": {"$ref": "users", "$id": uid}} # Full DBRef object
        ]
        
        for pattern in patterns:
            or_filters.append({"members": {"$elemMatch": pattern}})

    return await Community.find({"$or": or_filters}, fetch_links=fetch_links).to_list()