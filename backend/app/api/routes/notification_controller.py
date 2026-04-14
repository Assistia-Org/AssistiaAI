from fastapi import APIRouter, status
from backend.app.schemas.notification import NotificationCreate, NotificationOut, NotificationUpdate
from backend.app.services.notification_service import (
    create_notification_service,
    delete_notification_service,
    get_notification_service,
    list_notifications_by_user_service,
    update_notification_service,
    mark_notification_as_read_service,
)

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.post("/", response_model=NotificationOut, status_code=status.HTTP_201_CREATED)
async def create_notification(data: NotificationCreate) -> NotificationOut:
    """
    Bildirim oluşturma endpoint'i.
    Kullanıcıya veya sisteme ait yeni bir bildirim (alert/message) kaydeder.
    """
    return await create_notification_service(data)


@router.get("/{notification_id}", response_model=NotificationOut, status_code=status.HTTP_200_OK)
async def get_notification(notification_id: str) -> NotificationOut:
    """
    Bildirim detay getirme endpoint'i.
    Spesifik bir bildirimin içeriğini ve okunma durumunu getirir.
    """
    return await get_notification_service(notification_id)


@router.get("/user/{user_id}", response_model=list[NotificationOut], status_code=status.HTTP_200_OK)
async def list_user_notifications(user_id: str) -> list[NotificationOut]:
    """
    Kullanıcı bildirimlerini listeleme endpoint'i.
    Belirtilen kullanıcıya gelen tüm aktif bildirimleri listeler.
    """
    return await list_notifications_by_user_service(user_id)


@router.patch("/{notification_id}", response_model=NotificationOut, status_code=status.HTTP_200_OK)
async def update_notification(notification_id: str, data: NotificationUpdate) -> NotificationOut:
    """
    Bildirim güncelleme endpoint'i.
    Özellikle bildirimin diğer özelliklerini veya flaglerini güncel tutmayı sağlar.
    """
    return await update_notification_service(notification_id, data)


@router.patch("/{notification_id}/read", response_model=NotificationOut, status_code=status.HTTP_200_OK)
async def mark_notification_as_read(notification_id: str) -> NotificationOut:
    """
    Bildirimi okundu yapma endpoint'i.
    Spesifik bir indirilen/görüntülenen bildirimi "okundu" (is_read=True) olarak işaretler.
    """
    return await mark_notification_as_read_service(notification_id)


@router.delete("/{notification_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_notification(notification_id: str) -> None:
    """
    Bildirim silme endpoint'i.
    Gereksizleşen veya okunan bildirimleri soft-delete kullanarak sistemden kaldırır.
    """
    await delete_notification_service(notification_id)
