from beanie import PydanticObjectId
from app.models.task import Task
from app.schemas.task import TaskCreate, TaskUpdate


async def create_task(data: TaskCreate) -> Task:
    task = Task(**data.model_dump())
    return await task.insert()


async def get_task_by_id(task_id: str) -> Task | None:
    return await Task.get(PydanticObjectId(task_id))


async def get_tasks_by_user_id(user_id: str) -> list[Task]:
    return await Task.find(
        Task.user_id == PydanticObjectId(user_id)
    ).to_list()


async def list_tasks() -> list[Task]:
    return await Task.find_all().to_list()


async def update_task(task: Task, data: TaskUpdate) -> Task:
    update_data = data.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(task, key, value)

    return await task.save()


async def delete_task(task: Task) -> None:
    await task.delete()