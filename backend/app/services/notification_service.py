from fastapi import HTTPException
from backend.app.core.messages.error_message import NOTIFICATION_NOT_FOUND
from backend.app.repositories.notificaton import (
    create_notification,
    get_notification_by_id,
    get_notifications_by_user,
    update_notification,
    mark_notification_as_read,
    soft_delete_notification,
)
from backend.app.schemas.notification import NotificationCreate, NotificationUpdate, NotificationOut


async def create_notification_service(data: NotificationCreate) -> NotificationOut:
    """Orchestrate notification creation."""
    notification = await create_notification(data)
    return NotificationOut.model_validate(notification)


async def get_notification_service(notification_id: str) -> NotificationOut:
    """Orchestrate notification retrieval."""
    notification = await get_notification_by_id(notification_id)
    if not notification:
        raise HTTPException(status_code=404, detail=NOTIFICATION_NOT_FOUND)
    return NotificationOut.model_validate(notification)


async def list_notifications_by_user_service(user_id: str) -> list[NotificationOut]:
    """Orchestrate listing notifications for a user."""
    notifications = await get_notifications_by_user(user_id)
    return [NotificationOut.model_validate(n) for n in notifications]


async def update_notification_service(notification_id: str, data: NotificationUpdate) -> NotificationOut:
    """Orchestrate notification update."""
    notification = await update_notification(notification_id, data)
    if not notification:
        raise HTTPException(status_code=404, detail=NOTIFICATION_NOT_FOUND)
    return NotificationOut.model_validate(notification)


async def mark_notification_as_read_service(notification_id: str) -> NotificationOut:
    """Orchestrate marking notification as read."""
    notification = await mark_notification_as_read(notification_id)
    if not notification:
        raise HTTPException(status_code=404, detail=NOTIFICATION_NOT_FOUND)
    return NotificationOut.model_validate(notification)


async def delete_notification_service(notification_id: str) -> None:
    """Orchestrate notification soft deletion."""
    notification = await soft_delete_notification(notification_id)
    if not notification:
        raise HTTPException(status_code=404, detail=NOTIFICATION_NOT_FOUND)
