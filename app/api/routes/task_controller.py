from fastapi import APIRouter, status
from app.schemas.task import TaskCreate, TaskOut, TaskUpdate
from app.services.task_service import (
    create_task_service,
    delete_task_service,
    get_task_service,
    list_all_tasks_service,
    list_tasks_by_user_service,
    update_task_service,
)

router = APIRouter(prefix="/tasks", tags=["tasks"])


@router.post("/", response_model=TaskOut, status_code=status.HTTP_201_CREATED)
async def create_task(data: TaskCreate) -> TaskOut:
    """
    Görev oluşturma endpoint'i.
    Kullanıcı üzerinde yeni bir yapılacak iş (task) kaydı ekler.
    """
    return await create_task_service(data)


@router.get("/{task_id}", response_model=TaskOut, status_code=status.HTTP_200_OK)
async def get_task(task_id: str) -> TaskOut:
    """
    Görev detay getirme endpoint'i.
    Görev durumu (status), önceliği (priority) ve son tarihini (due_date) döner.
    """
    return await get_task_service(task_id)


@router.get("/user/{user_id}", response_model=list[TaskOut], status_code=status.HTTP_200_OK)
async def list_user_tasks(user_id: str) -> list[TaskOut]:
    """
    Kullanıcıya ait görevleri listeleme endpoint'i.
    İlgili kullanıcının tamamlanmış veya bekleyen tüm işlerini getirir.
    """
    return await list_tasks_by_user_service(user_id)


@router.get("/", response_model=list[TaskOut], status_code=status.HTTP_200_OK)
async def list_all_tasks() -> list[TaskOut]:
    """
    Sistemdeki tüm görevleri listeleme endpoint'i.
    Genelde admin/raporlama amacıyla kullanılan genelleştirilmiş görevleri getirir.
    """
    return await list_all_tasks_service()


@router.patch("/{task_id}", response_model=TaskOut, status_code=status.HTTP_200_OK)
async def update_task(task_id: str, data: TaskUpdate) -> TaskOut:
    """
    Görev güncelleme endpoint'i.
    Görev durumunu tamamlandı (completed) veya iptal olarak değiştirmek için biçilmiş kaftandır.
    """
    return await update_task_service(task_id, data)


@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_task(task_id: str) -> None:
    """
    Görev silme endpoint'i.
    İlgili görevi veritabanından tamamen çıkarır (hard/soft delete).
    """
    await delete_task_service(task_id)
