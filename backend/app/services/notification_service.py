from typing import Any, Optional
from fastapi import HTTPException
from app.core.events import event_manager
from app.core.firebase import send_push_notification
from app.core.messages.error_message import NOTIFICATION_NOT_FOUND
from app.models.notification import NotificationType
from app.models.user import User
from app.repositories.notification import (
    count_unread,
    create_notification,
    get_notification_by_id,
    get_notifications_by_user,
    mark_all_notifications_as_read,
    mark_notification_as_read,
    soft_delete_notification,
)
from app.repositories.user import get_fcm_token, get_user_by_id
from app.schemas.notification import NotificationListResponse, NotificationResponse


async def create_notification_service(
    user_id: str,
    type: NotificationType,
    title: str,
    body: str,
    metadata: Optional[dict[str, Any]] = None,
) -> NotificationResponse:
    """
    Persist a notification to the database and push it to the user via SSE.
    This is the single entry point for creating any notification in the system.
    """
    notification = await create_notification(
        user_id=user_id,
        type=type,
        title=title,
        body=body,
        metadata=metadata,
    )

    # Push real-time event so the client refreshes immediately (app open)
    await event_manager.publish(
        user_id,
        "new_notification",
        {
            "id": str(notification.id),
            "type": type,
            "title": title,
            "body": body,
        },
    )

    # FCM push — works even when app is closed (fire-and-forget, never raises)
    user = await get_user_by_id(user_id)
    if user and user.fcm_token and user.personal_settings.notifications:
        await send_push_notification(
            fcm_token=user.fcm_token,
            title=title,
            body=body,
            data={"type": type, "notification_id": str(notification.id)},
        )

    return NotificationResponse.model_validate(notification)


async def get_notifications_service(current_user: User) -> NotificationListResponse:
    """Return all notifications for the logged-in user with unread count."""
    notifications = await get_notifications_by_user(str(current_user.id))
    unread = await count_unread(str(current_user.id))
    return NotificationListResponse(
        notifications=[NotificationResponse.model_validate(n) for n in notifications],
        unread_count=unread,
    )


async def mark_as_read_service(current_user: User, notification_id: str) -> NotificationResponse:
    """Mark a single notification as read. Raises 404 if not found or not owned by user."""
    notification = await get_notification_by_id(notification_id)
    if not notification or notification.user_id != str(current_user.id):
        raise HTTPException(status_code=404, detail=NOTIFICATION_NOT_FOUND)

    updated = await mark_notification_as_read(notification)
    return NotificationResponse.model_validate(updated)


async def mark_all_as_read_service(current_user: User) -> dict:
    """Mark all unread notifications as read for the logged-in user."""
    updated_count = await mark_all_notifications_as_read(str(current_user.id))
    return {"updated_count": updated_count}


async def delete_notification_service(current_user: User, notification_id: str) -> None:
    """Soft-delete a notification. Raises 404 if not found or not owned by user."""
    notification = await get_notification_by_id(notification_id)
    if not notification or notification.user_id != str(current_user.id):
        raise HTTPException(status_code=404, detail=NOTIFICATION_NOT_FOUND)

    await soft_delete_notification(notification)
