from beanie import PydanticObjectId
from backend.app.models.notification import Notification
from backend.app.schemas.notification import NotificationCreate, NotificationUpdate


async def create_notification(data: NotificationCreate) -> Notification:
    notification = Notification(**data.model_dump())
    return await notification.insert()


async def get_notification_by_id(notification_id: str) -> Notification | None:
    try:
        obj_id = PydanticObjectId(notification_id)
    except Exception:
        return None

    notification = await Notification.get(obj_id)

    if not notification:
        return None

    if getattr(notification, "is_deleted", False):
        return None

    return notification


async def get_notifications_by_user(user_id: str) -> list[Notification]:
    try:
        obj_id = PydanticObjectId(user_id)
    except Exception:
        return []

    return await Notification.find(
        Notification.user_id == obj_id,
        Notification.is_deleted == False
    ).sort(-Notification.created_at).to_list()


async def update_notification(
    notification_id: str,
    data: NotificationUpdate
) -> Notification | None:
    notification = await get_notification_by_id(notification_id)
    if not notification:
        return None

    update_data = data.model_dump(exclude_unset=True)

    for field, value in update_data.items():
        setattr(notification, field, value)

    await notification.save()
    return notification


async def mark_notification_as_read(notification_id: str) -> Notification | None:
    notification = await get_notification_by_id(notification_id)
    if not notification:
        return None

    notification.is_read = True
    await notification.save()
    return notification


async def soft_delete_notification(notification_id: str) -> Notification | None:
    notification = await get_notification_by_id(notification_id)
    if not notification:
        return None

    notification.is_deleted = True
    await notification.save()
    return notification