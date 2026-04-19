from fastapi import HTTPException
from app.core.messages.error_message import TASK_NOT_FOUND
from app.repositories.task import (
    create_task,
    get_task_by_id,
    get_tasks_by_user_id,
    list_tasks,
    update_task,
    delete_task,
)
from app.schemas.task import TaskCreate, TaskUpdate, TaskResponse


from datetime import date
from app.models.daily_program import DailyProgramSummary, DailyProgramItems
from app.repositories.daily_program import (
    get_program_by_user_and_date,
    create_daily_program
)

async def create_task_service(creator_id: str, data: TaskCreate) -> TaskResponse:
    """
    Orchestrate task creation and DailyProgram sync.
    1. Determine target date
    2. Find/Create DailyProgram
    3. Save Task and Link to Program
    """
    # 1. Determine target date (due_date or today)
    target_date = data.due_date.date() if data.due_date else date.today()

    # 2. Find or Create DailyProgram
    program = await get_program_by_user_and_date(creator_id, target_date)
    if not program:
        program_data = {
            "tarih": target_date,
            "kullanici_id": creator_id,
            "ozet": DailyProgramSummary(task_sayisi=0, etkinlik_sayisi=0),
            "items": DailyProgramItems(tasks=[], etkinlikler=[])
        }
        program = await create_daily_program(program_data)

    # 3. Save Task
    data.creator_id = creator_id
    if creator_id not in data.assigned_to:
        data.assigned_to.append(creator_id)
        
    task = await create_task(data.model_dump())
    
    # 4. Link to Program
    program.items.tasks.append(task) # Beanie Link handles this
    program.ozet.task_sayisi += 1
    await program.save()

    return TaskResponse.model_validate(task)


async def get_task_service(task_id: str) -> TaskResponse:
    """Orchestrate task retrieval."""
    task = await get_task_by_id(task_id)
    if not task:
        raise HTTPException(status_code=404, detail=TASK_NOT_FOUND)
    return TaskResponse.model_validate(task)


async def list_tasks_by_user_service(user_id: str) -> list[TaskResponse]:
    """Orchestrate listing tasks for a user."""
    tasks = await get_tasks_by_user_id(user_id)
    return [TaskResponse.model_validate(t) for t in tasks]


async def list_all_tasks_service() -> list[TaskResponse]:
    """Orchestrate listing all tasks."""
    tasks = await list_tasks()
    return [TaskResponse.model_validate(t) for t in tasks]


async def update_task_service(task_id: str, data: TaskUpdate) -> TaskResponse:
    """Orchestrate task update."""
    task = await get_task_by_id(task_id)
    if not task:
        raise HTTPException(status_code=404, detail=TASK_NOT_FOUND)
    
    updated_task = await update_task(task, data.model_dump(exclude_unset=True))
    return TaskResponse.model_validate(updated_task)


async def delete_task_service(task_id: str) -> None:
    """Orchestrate task deletion."""
    task = await get_task_by_id(task_id)
    if not task:
        raise HTTPException(status_code=404, detail=TASK_NOT_FOUND)
    await delete_task(task)
