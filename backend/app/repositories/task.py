from typing import List, Optional
from datetime import datetime
from app.models.task import Task
from app.db import get_database


class TaskRepository:
    def __init__(self):
        self.db = get_database()
        self.collection = self.db["tasks"]

    # CREATE
    async def create(self, task: Task) -> Task:
        data = task.dict(by_alias=True)
        await self.collection.insert_one(data)
        return task

    # GET BY ID
    async def get_by_id(self, task_id: str) -> Optional[Task]:
        doc = await self.collection.find_one({"_id": task_id})
        if doc:
            return Task(**doc)
        return None

    # LIST ALL
    async def list(self) -> List[Task]:
        tasks = []
        cursor = self.collection.find()

        async for doc in cursor:
            tasks.append(Task(**doc))

        return tasks

    # LIST BY CREATOR
    async def list_by_creator(self, creator_id: str) -> List[Task]:
        tasks = []
        cursor = self.collection.find({"creator_id": creator_id})

        async for doc in cursor:
            tasks.append(Task(**doc))

        return tasks

    # LIST BY ASSIGNED USER
    async def list_by_assigned_user(self, user_id: str) -> List[Task]:
        tasks = []
        cursor = self.collection.find({"assigned_to": user_id})

        async for doc in cursor:
            tasks.append(Task(**doc))

        return tasks

    # LIST BY COMMUNITY
    async def list_by_community(self, community_id: str) -> List[Task]:
        tasks = []
        cursor = self.collection.find({"community_id": community_id})

        async for doc in cursor:
            tasks.append(Task(**doc))

        return tasks

    # UPDATE STATUS
    async def update_status(self, task_id: str, status: str) -> bool:
        result = await self.collection.update_one(
            {"_id": task_id},
            {"$set": {"status": status}}
        )
        return result.modified_count > 0

    # UPDATE PRIORITY
    async def update_priority(self, task_id: str, priority: str) -> bool:
        result = await self.collection.update_one(
            {"_id": task_id},
            {"$set": {"priority": priority}}
        )
        return result.modified_count > 0

    # ASSIGN USER
    async def assign_user(self, task_id: str, user_id: str) -> bool:
        result = await self.collection.update_one(
            {"_id": task_id},
            {"$addToSet": {"assigned_to": user_id}}
        )
        return result.modified_count > 0

    # UNASSIGN USER
    async def unassign_user(self, task_id: str, user_id: str) -> bool:
        result = await self.collection.update_one(
            {"_id": task_id},
            {"$pull": {"assigned_to": user_id}}
        )
        return result.modified_count > 0

    # UPDATE TAGS
    async def add_tag(self, task_id: str, tag: str) -> bool:
        result = await self.collection.update_one(
            {"_id": task_id},
            {"$addToSet": {"tags": tag}}
        )
        return result.modified_count > 0

    async def remove_tag(self, task_id: str, tag: str) -> bool:
        result = await self.collection.update_one(
            {"_id": task_id},
            {"$pull": {"tags": tag}}
        )
        return result.modified_count > 0

    # UPDATE DUE DATE
    async def update_due_date(self, task_id: str, due_date: Optional[datetime]) -> bool:
        result = await self.collection.update_one(
            {"_id": task_id},
            {"$set": {"due_date": due_date}}
        )
        return result.modified_count > 0

    # DELETE
    async def delete(self, task_id: str) -> bool:
        result = await self.collection.delete_one({"_id": task_id})
        return result.deleted_count > 0