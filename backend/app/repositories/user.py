from typing import List, Optional
from app.models.user import User, CommunityRoleModel, PersonalSettingsModel
from app.db import get_database


class UserRepository:
    def __init__(self):
        self.db = get_database()
        self.collection = self.db["users"]

    # CREATE
    async def create(self, user: User) -> User:
        data = user.dict(by_alias=True)
        await self.collection.insert_one(data)
        return user

    # GET BY ID
    async def get_by_id(self, user_id: str) -> Optional[User]:
        doc = await self.collection.find_one({"_id": user_id})
        if doc:
            return User(**doc)
        return None

    # GET BY EMAIL
    async def get_by_email(self, email: str) -> Optional[User]:
        doc = await self.collection.find_one({"email": email})
        if doc:
            return User(**doc)
        return None

    # GET BY USERNAME
    async def get_by_username(self, username: str) -> Optional[User]:
        doc = await self.collection.find_one({"username": username})
        if doc:
            return User(**doc)
        return None

    # LIST ALL
    async def list(self) -> List[User]:
        users = []
        cursor = self.collection.find()

        async for doc in cursor:
            users.append(User(**doc))

        return users

    # ADD COMMUNITY ROLE
    async def add_community_role(self, user_id: str, role_data: CommunityRoleModel) -> bool:
        result = await self.collection.update_one(
            {"_id": user_id},
            {"$push": {"joined_communities": role_data.dict()}}
        )
        return result.modified_count > 0

    # REMOVE COMMUNITY ROLE
    async def remove_community_role(self, user_id: str, community_id: str) -> bool:
        result = await self.collection.update_one(
            {"_id": user_id},
            {"$pull": {"joined_communities": {"community_id": community_id}}}
        )
        return result.modified_count > 0

    # UPDATE COMMUNITY ROLE
    async def update_community_role(self, user_id: str, community_id: str, new_role: str) -> bool:
        result = await self.collection.update_one(
            {
                "_id": user_id,
                "joined_communities.community_id": community_id
            },
            {
                "$set": {
                    "joined_communities.$.role": new_role
                }
            }
        )
        return result.modified_count > 0

    # UPDATE PERSONAL SETTINGS
    async def update_personal_settings(
        self,
        user_id: str,
        settings: PersonalSettingsModel
    ) -> bool:
        result = await self.collection.update_one(
            {"_id": user_id},
            {"$set": {"personal_settings": settings.dict()}}
        )
        return result.modified_count > 0

    # UPDATE AVATAR
    async def update_avatar(self, user_id: str, avatar_url: Optional[str]) -> bool:
        result = await self.collection.update_one(
            {"_id": user_id},
            {"$set": {"avatar_url": avatar_url}}
        )
        return result.modified_count > 0

    # DELETE
    async def delete(self, user_id: str) -> bool:
        result = await self.collection.delete_one({"_id": user_id})
        return result.deleted_count > 0