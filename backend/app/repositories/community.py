from typing import List, Optional
from app.models.community import Community, CommunityMember
from app.db import get_database

class CommunityRepository:
    def __init__(self):
        self.db = get_database()
        self.collection = self.db["communities"]

    # CREATE
    async def create(self, community: Community) -> Community:
        data = community.dict(by_alias=True)
        await self.collection.insert_one(data)
        return community

    # GET BY ID
    async def get_by_id(self, community_id: str) -> Optional[Community]:
        doc = await self.collection.find_one({"_id": community_id})
        if doc:
            return Community(**doc)
        return None

    # LIST ALL
    async def list(self) -> List[Community]:
        communities = []
        cursor = self.collection.find()

        async for doc in cursor:
            communities.append(Community(**doc))

        return communities

    # ADD MEMBER
    async def add_member(self, community_id: str, member: CommunityMember):
        await self.collection.update_one(
            {"_id": community_id},
            {"$push": {"members": member.dict()}}
        )

    # REMOVE MEMBER
    async def remove_member(self, community_id: str, user_id: str):
        await self.collection.update_one(
            {"_id": community_id},
            {"$pull": {"members": {"user_id": user_id}}}
        )

    # DELETE
    async def delete(self, community_id: str):
        await self.collection.delete_one({"_id": community_id})