from fastapi import APIRouter, status, Depends
from app.schemas.task import TaskCreate, TaskResponse, TaskUpdate
from app.services.task_service import (
    create_task_service,
    delete_task_service,
    get_task_service,
    list_all_tasks_service,
    list_tasks_by_user_service,
    update_task_service,
)
from app.api.dependencies.auth import get_current_user
from app.models.user import User

router = APIRouter(prefix="/tasks", tags=["tasks"])


@router.post("/", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
async def create_task(
    data: TaskCreate, 
    current_user: User = Depends(get_current_user)
) -> TaskResponse:
    """
    Görev oluşturma endpoint'i.
    Kullanıcı üzerinde yeni bir yapılacak iş (task) kaydı ekler.
    """
    return await create_task_service(str(current_user.id), data)


@router.get("/{task_id}", response_model=TaskResponse, status_code=status.HTTP_200_OK)
async def get_task(
    task_id: str, 
    current_user: User = Depends(get_current_user)
) -> TaskResponse:
    """
    Görev detay getirme endpoint'i.
    Görev durumu (status), önceliği (priority) ve son tarihini (due_date) döner.
    """
    return await get_task_service(task_id)


@router.get("/user/{user_id}", response_model=list[TaskResponse], status_code=status.HTTP_200_OK)
async def list_user_tasks(
    user_id: str, 
    current_user: User = Depends(get_current_user)
) -> list[TaskResponse]:
    """
    Kullanıcıya ait görevleri listeleme endpoint'i.
    İlgili kullanıcının tamamlanmış veya bekleyen tüm işlerini getirir.
    """
    # Note: In a real app, you might want to check if current_user.id == user_id
    return await list_tasks_by_user_service(user_id)


@router.get("/", response_model=list[TaskResponse], status_code=status.HTTP_200_OK)
async def list_all_tasks(
    current_user: User = Depends(get_current_user)
) -> list[TaskResponse]:
    """
    Sistemdeki tüm görevleri listeleme endpoint'i.
    Genelde admin/raporlama amacıyla kullanılan genelleştirilmiş görevleri getirir.
    """
    return await list_all_tasks_service()


@router.patch("/{task_id}", response_model=TaskResponse, status_code=status.HTTP_200_OK)
async def update_task(
    task_id: str, 
    data: TaskUpdate, 
    current_user: User = Depends(get_current_user)
) -> TaskResponse:
    """
    Görev güncelleme endpoint'i.
    Görev durumunu tamamlandı (completed), işlemde (in_progress) veya bekliyor (pending) olarak değiştirmek için kullanılır.
    """
    return await update_task_service(task_id, data)


@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_task(
    task_id: str, 
    current_user: User = Depends(get_current_user)
) -> None:
    """
    Görev silme endpoint'i.
    İlgili görevi veritabanından tamamen çıkarır (hard/soft delete).
    """
    await delete_task_service(task_id)
