from fastapi import HTTPException
from app.repositories.task import (
    create_task,
    get_task_by_id,
    get_tasks_by_user_id,
    list_tasks,
    update_task,
    delete_task,
)
from app.schemas.task import TaskCreate, TaskUpdate, TaskResponse
from app.repositories.community import get_community_by_id
from app.core.messages.error_message import TASK_NOT_FOUND, UNAUTHORIZED_COMMUNITY_ACTION


from datetime import date, datetime, timezone
from app.models.task import Task, TaskStatus
from app.models.user import User
from app.models.daily_program import DailyProgramSummary, DailyProgramItems
from app.repositories.daily_program import (
    get_program_by_user_and_date,
    create_daily_program
)

async def sync_task_status(task: Task) -> Task:
    """
    Automatically update task status based on current time.
    Logic:
    - If status is COMPLETED, keep it.
    - If now < start_date: PENDING
    - If start_date <= now < end_date: IN_PROGRESS
    - If now >= end_date: OVERDUE
    """
    if task.status == TaskStatus.COMPLETED:
        return task

    # Use UTC for comparison as Beanie/MongoDB stores in UTC by default
    now = datetime.now(timezone.utc)
    
    # If the task dates are naive, make now naive too to allow comparison
    # Beanie usually returns aware datetimes if stored as UTC, but safety first
    if task.start_date and task.start_date.tzinfo is None:
        now = datetime.utcnow()
    elif task.end_date and task.end_date.tzinfo is None:
        now = datetime.utcnow()
        
    new_status = task.status

    # User requested logic order:
    # 1. Check end_date first
    if task.end_date and now >= task.end_date:
        new_status = TaskStatus.OVERDUE
    # 2. If not passed end_date, check start_date
    elif task.start_date and now >= task.start_date:
        new_status = TaskStatus.IN_PROGRESS
    # 3. Otherwise it's pending
    else:
        new_status = TaskStatus.PENDING
    
    # Persist the status if it changed
    if new_status != task.status:
        task.status = new_status
        await task.save()
    
    return task

async def create_task_service(current_user: User, data: TaskCreate) -> TaskResponse:
    """
    Orchestrate task creation and DailyProgram sync for all assigned users.
    1. Validate community ownership if community_id is provided.
    2. Determine target users.
    3. Save Task.
    4. Link to DailyProgram for all target users.
    5. Notify assigned users.
    """
    creator_id = str(current_user.id)
    # 1. Validate community ownership
    community_name = None
    target_users = set()
    
    if data.community_id:
        community = await get_community_by_id(data.community_id)
        if not community:
            from app.core.messages.error_message import COMMUNITY_NOT_FOUND
            raise HTTPException(status_code=404, detail=COMMUNITY_NOT_FOUND)
        
        # Only owner can assign tasks to community or other members
        if community.owner_id != creator_id:
            raise HTTPException(status_code=403, detail=UNAUTHORIZED_COMMUNITY_ACTION)
        
        community_name = community.name
        
        # Determine target users
        if not data.assigned_to:
            # If assigned_to is empty, it means entire community
            target_users = {str(m.user.id) for m in community.members}
        else:
            # Ensure assigned users are members? For now assume valid or let it fail
            target_users = set(data.assigned_to)
    else:
        # Personal task
        target_users = set(data.assigned_to) if data.assigned_to else {creator_id}

    # Ensure creator is in assigned_to if it's personal and assigned_to was empty
    if not data.community_id and creator_id not in target_users:
        target_users.add(creator_id)

    # 2. Determine target date (due_date, start_date or today)
    if data.due_date:
        target_date = data.due_date.date()
    elif data.start_date:
        target_date = data.start_date.date()
    else:
        target_date = date.today()

    # 3. Save Task
    data.creator_id = creator_id
    data.assigned_to = list(target_users)
    
    task_dict = data.model_dump()
    task_dict["status"] = TaskStatus.PENDING
    
    task = await create_task(task_dict)
    
    # 4. Link to Programs for all target users
    for user_id in target_users:
        program = await get_program_by_user_and_date(user_id, target_date)
        if not program:
            program_data = {
                "tarih": target_date,
                "kullanici_id": user_id,
                "ozet": DailyProgramSummary(task_sayisi=0, etkinlik_sayisi=0),
                "items": DailyProgramItems(tasks=[], etkinlikler=[])
            }
            program = await create_daily_program(program_data)

        # Check if already added to avoid duplicates
        if not any(str(t.id) == str(task.id) for t in program.items.tasks):
            program.items.tasks.append(task)
            program.ozet.task_sayisi += 1
            await program.save()

    # 5. Notify assigned users
    from app.services.notification_service import create_notification_service
    from app.models.notification import NotificationType
    
    for user_id in target_users:
        if user_id != creator_id:
            await create_notification_service(
                user_id=user_id,
                type=NotificationType.INVITATION, # Using INVITATION type for general community notifications for now or add a new one
                title="Yeni Görev Atandı",
                body=f"{current_user.display_name} sana bir görev atadı: {task.title}",
                metadata={"task_id": str(task.id), "community_id": data.community_id},
            )

    response = TaskResponse.model_validate(task)
    response.community_name = community_name
    return response


async def get_task_service(task_id: str) -> TaskResponse:
    """Orchestrate task retrieval."""
    task = await get_task_by_id(task_id)
    if not task:
        raise HTTPException(status_code=404, detail=TASK_NOT_FOUND)
    
    task = await sync_task_status(task)
    response = TaskResponse.model_validate(task)
    
    if task.community_id:
        community = await get_community_by_id(task.community_id)
        if community:
            response.community_name = community.name
            
    return response


async def list_tasks_by_user_service(user_id: str) -> list[TaskResponse]:
    """Orchestrate listing tasks for a user."""
    tasks = await get_tasks_by_user_id(user_id)
    synced_tasks = [await sync_task_status(t) for t in tasks]
    
    responses = []
    for t in synced_tasks:
        res = TaskResponse.model_validate(t)
        if t.community_id:
            community = await get_community_by_id(t.community_id)
            if community:
                res.community_name = community.name
        responses.append(res)
    return responses


async def list_all_tasks_service() -> list[TaskResponse]:
    """Orchestrate listing all tasks."""
    tasks = await list_tasks()
    synced_tasks = [await sync_task_status(t) for t in tasks]
    return [TaskResponse.model_validate(t) for t in synced_tasks]


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
