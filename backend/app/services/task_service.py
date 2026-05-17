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
from app.core.logger import logger, EventType


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

def get_task_target_date(task: Task) -> date:
    """Return the target date of a task based on due_date, start_date, or today."""
    if task.due_date:
        return task.due_date.date()
    elif task.start_date:
        return task.start_date.date()
    return date.today()


async def move_task_in_daily_programs(task: Task, old_date: date, new_date: date, user_id: str) -> None:
    """Move a task from an old daily program date to a new daily program date for a user."""
    if old_date == new_date:
        return

    # 1. Remove from old daily program
    old_program = await get_program_by_user_and_date(user_id, old_date)
    if old_program:
        original_len = len(old_program.items.tasks)
        old_program.items.tasks = [t for t in old_program.items.tasks if str(getattr(t, "id", t)) != str(task.id)]
        if len(old_program.items.tasks) < original_len:
            old_program.ozet.task_sayisi -= (original_len - len(old_program.items.tasks))
            if old_program.ozet.task_sayisi < 0:
                old_program.ozet.task_sayisi = 0
            await old_program.save()

    # 2. Add to new daily program
    new_program = await get_program_by_user_and_date(user_id, new_date)
    if not new_program:
        program_data = {
            "tarih": new_date,
            "kullanici_id": user_id,
            "ozet": DailyProgramSummary(task_sayisi=0, etkinlik_sayisi=0),
            "items": DailyProgramItems(tasks=[], etkinlikler=[])
        }
        new_program = await create_daily_program(program_data)

    if not any(str(t.id) == str(task.id) for t in new_program.items.tasks):
        new_program.items.tasks.append(task)
        new_program.ozet.task_sayisi += 1
        await new_program.save()


async def create_task_service(current_user: User, data: TaskCreate) -> TaskResponse:
    """
    Orchestrate task creation and DailyProgram sync for all assigned users.
    Splits the task into a separate document per user to ensure independent statuses.
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

    # 3. Save Task (split into separate documents per target user)
    data.creator_id = creator_id
    target_users_list = list(target_users)
    if not target_users_list:
        target_users_list = [creator_id]

    created_tasks = []
    
    if len(target_users_list) > 1:
        # Create first task copy to establish the parent_id
        first_user = target_users_list[0]
        data.assigned_to = [first_user]
        task_dict = data.model_dump()
        task_dict["status"] = TaskStatus.PENDING
        
        first_task = await create_task(task_dict)
        parent_id = str(first_task.id)
        
        first_task.parent_task_id = parent_id
        await first_task.save()
        created_tasks.append(first_task)
        
        # Create copies for other users
        for user_id in target_users_list[1:]:
            data.assigned_to = [user_id]
            task_dict = data.model_dump()
            task_dict["status"] = TaskStatus.PENDING
            task_dict["parent_task_id"] = parent_id
            
            task = await create_task(task_dict)
            created_tasks.append(task)
    else:
        # Single user task
        single_user = target_users_list[0]
        data.assigned_to = [single_user]
        task_dict = data.model_dump()
        task_dict["status"] = TaskStatus.PENDING
        
        task = await create_task(task_dict)
        task.parent_task_id = str(task.id)
        await task.save()
        created_tasks.append(task)

    # 4. Link to Programs for each user with their respective task copy
    for task in created_tasks:
        user_id = task.assigned_to[0]
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
    
    for task in created_tasks:
        user_id = task.assigned_to[0]
        if user_id != creator_id:
            await create_notification_service(
                user_id=user_id,
                type=NotificationType.INVITATION,
                title="Yeni Görev Atandı",
                body=f"{current_user.display_name} sana bir görev atadı: {task.title}",
                metadata={"task_id": str(task.id), "community_id": data.community_id},
            )

    creator_task = next((t for t in created_tasks if t.assigned_to[0] == creator_id), created_tasks[0])
    response = TaskResponse.model_validate(creator_task)
    response.community_name = community_name
    await logger.info(
        EventType.TASK_CREATE,
        f"Görev oluşturuldu: {creator_task.title}",
        user_id=creator_id,
        extra={
            "task_id": str(creator_task.id),
            "community_id": data.community_id,
            "assigned_to": target_users_list,
            "parent_task_id": creator_task.parent_task_id,
        },
    )
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


async def update_task_service(task_id: str, data: TaskUpdate, current_user: User) -> TaskResponse:
    """
    Orchestrate task update.
    If the creator is updating general fields (excluding status/assigned_to), propagate changes to all other copies.
    """
    task = await get_task_by_id(task_id)
    if not task:
        raise HTTPException(status_code=404, detail=TASK_NOT_FOUND)

    user_id = str(current_user.id)
    is_creator = task.creator_id == user_id

    # Record the old target date before update
    old_date = get_task_target_date(task)
    update_dict = data.model_dump(exclude_unset=True)

    # Update current task
    updated_task = await update_task(task, update_dict)
    
    # Sync program date for current task if date changed
    new_date = get_task_target_date(updated_task)
    assigned_user_id = updated_task.assigned_to[0] if updated_task.assigned_to else user_id
    await move_task_in_daily_programs(updated_task, old_date, new_date, assigned_user_id)

    # If creator is updating and task is part of a split group, propagate changes (excluding status/assigned_to)
    if is_creator and updated_task.parent_task_id:
        propagate_dict = {k: v for k, v in update_dict.items() if k not in ("status", "assigned_to")}
        if propagate_dict:
            other_tasks = await Task.find(Task.parent_task_id == updated_task.parent_task_id, Task.id != updated_task.id).to_list()
            for other_task in other_tasks:
                other_old_date = get_task_target_date(other_task)
                other_updated_task = await update_task(other_task, propagate_dict)
                other_new_date = get_task_target_date(other_updated_task)
                other_assigned_user_id = other_updated_task.assigned_to[0] if other_updated_task.assigned_to else other_updated_task.creator_id
                await move_task_in_daily_programs(other_updated_task, other_old_date, other_new_date, other_assigned_user_id)

    await logger.info(
        EventType.TASK_UPDATE,
        f"Görev güncellendi: {task_id}",
        extra={"task_id": task_id, "fields": list(update_dict.keys())},
    )
    return TaskResponse.model_validate(updated_task)


async def delete_task_service(task_id: str, current_user: User) -> None:
    """
    Orchestrate task deletion.
    - If current_user is the creator: Delete all copies of the task globally and clean up programs.
    - If current_user is just assigned: Delete their copy of the task and clean up their program.
    """
    task = await get_task_by_id(task_id)
    if not task:
        raise HTTPException(status_code=404, detail=TASK_NOT_FOUND)

    user_id = str(current_user.id)
    is_creator = task.creator_id == user_id
    target_date = get_task_target_date(task)

    if is_creator:
        # Find all split tasks belonging to this group
        tasks_to_delete = []
        if task.parent_task_id:
            tasks_to_delete = await Task.find(Task.parent_task_id == task.parent_task_id).to_list()
        else:
            tasks_to_delete = [task]

        for t in tasks_to_delete:
            t_id = str(t.id)
            assigned_user_id = t.assigned_to[0] if t.assigned_to else t.creator_id
            
            program = await get_program_by_user_and_date(assigned_user_id, target_date)
            if program:
                original_len = len(program.items.tasks)
                program.items.tasks = [item for item in program.items.tasks if str(getattr(item, "id", item)) != t_id]
                
                if len(program.items.tasks) < original_len:
                    program.ozet.task_sayisi -= (original_len - len(program.items.tasks))
                    if program.ozet.task_sayisi < 0:
                        program.ozet.task_sayisi = 0
                    await program.save()
            
            await delete_task(t)

        await logger.warning(
            EventType.TASK_DELETE,
            f"Görev lider tarafından herkes için silindi: {task_id}",
            extra={"task_id": task_id, "creator_id": user_id, "parent_task_id": task.parent_task_id},
        )
    else:
        # Cleanup DailyProgram ONLY for the current user
        program = await get_program_by_user_and_date(user_id, target_date)
        if program:
            original_len = len(program.items.tasks)
            program.items.tasks = [t for t in program.items.tasks if str(getattr(t, "id", t)) != task_id]
            
            if len(program.items.tasks) < original_len:
                program.ozet.task_sayisi -= (original_len - len(program.items.tasks))
                if program.ozet.task_sayisi < 0:
                    program.ozet.task_sayisi = 0
                await program.save()

        # Delete this user's task document
        await delete_task(task)

        await logger.info(
            EventType.TASK_UPDATE,
            f"Kullanıcı görevi kendi listesinden sildi: {task_id}",
            extra={"task_id": task_id, "user_id": user_id},
        )
