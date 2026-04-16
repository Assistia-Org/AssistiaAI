from fastapi import HTTPException
from backend.app.core.messages.error_message import TASK_NOT_FOUND
from backend.app.repositories.task import (
    create_task,
    get_task_by_id,
    get_tasks_by_user_id,
    list_tasks,
    update_task,
    delete_task,
)
from backend.app.schemas.task import TaskCreate, TaskUpdate, TaskOut


async def create_task_service(data: TaskCreate) -> TaskOut:
    """Orchestrate task creation."""
    task = await create_task(data.model_dump())
    return TaskOut.model_validate(task)


async def get_task_service(task_id: str) -> TaskOut:
    """Orchestrate task retrieval."""
    task = await get_task_by_id(task_id)
    if not task:
        raise HTTPException(status_code=404, detail=TASK_NOT_FOUND)
    return TaskOut.model_validate(task)


async def list_tasks_by_user_service(user_id: str) -> list[TaskOut]:
    """Orchestrate listing tasks for a user."""
    tasks = await get_tasks_by_user_id(user_id)
    return [TaskOut.model_validate(t) for t in tasks]


async def list_all_tasks_service() -> list[TaskOut]:
    """Orchestrate listing all tasks."""
    tasks = await list_tasks()
    return [TaskOut.model_validate(t) for t in tasks]


async def update_task_service(task_id: str, data: TaskUpdate) -> TaskOut:
    """Orchestrate task update."""
    task = await get_task_by_id(task_id)
    if not task:
        raise HTTPException(status_code=404, detail=TASK_NOT_FOUND)
    
    updated_task = await update_task(task, data.model_dump(exclude_unset=True))
    return TaskOut.model_validate(updated_task)


async def delete_task_service(task_id: str) -> None:
    """Orchestrate task deletion."""
    task = await get_task_by_id(task_id)
    if not task:
        raise HTTPException(status_code=404, detail=TASK_NOT_FOUND)
    await delete_task(task)
