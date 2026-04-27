from typing import Any, List, Optional
from app.models.notification import Notification, NotificationType


async def create_notification(
    user_id: str,
    type: NotificationType,
    title: str,
    body: str,
    metadata: Optional[dict[str, Any]] = None,
) -> Notification:
    """Insert a new notification document and return it."""
    notification = Notification(
        user_id=user_id,
        type=type,
        title=title,
        body=body,
        metadata=metadata,
    )
    return await notification.insert()


async def get_notifications_by_user(user_id: str) -> List[Notification]:
    """Return all non-deleted notifications for a user, newest first."""
    return (
        await Notification.find(
            Notification.user_id == user_id,
            Notification.is_deleted == False,
        )
        .sort(-Notification.created_at)
        .to_list()
    )


async def get_notification_by_id(notification_id: str) -> Optional[Notification]:
    """Return a notification by ID or None if not found."""
    return await Notification.find_one(
        Notification.id == notification_id,
        Notification.is_deleted == False,
    )


async def count_unread(user_id: str) -> int:
    """Return the number of unread notifications for a user."""
    return await Notification.find(
        Notification.user_id == user_id,
        Notification.is_read == False,
        Notification.is_deleted == False,
    ).count()


async def mark_notification_as_read(notification: Notification) -> Notification:
    """Mark a single notification as read and save."""
    notification.is_read = True
    return await notification.save()


async def mark_all_notifications_as_read(user_id: str) -> int:
    """Mark all unread notifications for a user as read. Returns updated count."""
    result = await Notification.find(
        Notification.user_id == user_id,
        Notification.is_read == False,
        Notification.is_deleted == False,
    ).update({"$set": {"is_read": True}})
    return result.modified_count


async def soft_delete_notification(notification: Notification) -> None:
    """Soft-delete a notification by setting is_deleted=True."""
    notification.is_deleted = True
    await notification.save()
