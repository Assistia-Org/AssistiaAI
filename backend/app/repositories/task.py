from typing import List, Optional
from datetime import datetime
from app.models.task import Task, TaskStatus

async def create_task(task_data: dict) -> Task:
    """Create a new task and return the inserted document."""
    task = Task(**task_data)
    return await task.insert()

async def get_task_by_id(task_id: str) -> Optional[Task]:
    """Return task by ID or None if not found."""
    return await Task.find_one(Task.id == task_id)

async def list_tasks() -> List[Task]:
    """Return all tasks."""
    return await Task.find_all().to_list()

async def get_tasks_by_creator(creator_id: str) -> List[Task]:
    """Return tasks created by a specific user."""
    return await Task.find(Task.creator_id == creator_id).to_list()

async def get_tasks_by_user_id(user_id: str) -> List[Task]:
    """Return tasks assigned to a specific user."""
    # Maps to get_tasks_by_user_id used in task_service.py
    return await Task.find(Task.assigned_to == user_id).to_list()

async def list_tasks_by_community(community_id: str) -> List[Task]:
    """Return tasks for a specific community."""
    return await Task.find(Task.community_id == community_id).to_list()

async def update_status(task_id: str, status: str) -> bool:
    """Update task status."""
    task = await get_task_by_id(task_id)
    if not task:
        return False
    task.status = status
    await task.save()
    return True

async def update_priority(task_id: str, priority: str) -> bool:
    """Update task priority."""
    task = await get_task_by_id(task_id)
    if not task:
        return False
    task.priority = priority
    await task.save()
    return True

async def assign_user(task_id: str, user_id: str) -> bool:
    """Assign a user to a task."""
    task = await get_task_by_id(task_id)
    if not task:
        return False
    if user_id not in task.assigned_to:
        task.assigned_to.append(user_id)
        await task.save()
    return True

async def unassign_user(task_id: str, user_id: str) -> bool:
    """Unassign a user from a task."""
    task = await get_task_by_id(task_id)
    if not task:
        return False
    if user_id in task.assigned_to:
        task.assigned_to.remove(user_id)
        await task.save()
    return True

async def update_task(task: Task, data: dict) -> Task:
    """Update task document with provided data."""
    for key, value in data.items():
        if hasattr(task, key):
            setattr(task, key, value)
    return await task.save()

async def delete_task(task: Task) -> bool:
    """Delete a task document."""
    await task.delete()
    return True

async def get_my_tasks(user_id: str, status: Optional[TaskStatus] = None) -> List[Task]:
    try:
       
        query = {"creator_id": user_id, "is_deleted": False}
        
        if status:
            query["status"] = status.value

        return await Task.find(query).to_list()
    except Exception as e:
        print(f"Hata: {e}")
        return []