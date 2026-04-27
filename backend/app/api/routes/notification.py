from fastapi import APIRouter, Depends, status
from app.api.dependencies.auth import get_current_user
from app.models.user import User
from app.schemas.notification import NotificationListResponse, NotificationResponse
from app.services.notification_service import (
    delete_notification_service,
    get_notifications_service,
    mark_all_as_read_service,
    mark_as_read_service,
)
from app.core.messages.success_message import (
    ALL_NOTIFICATIONS_MARKED_READ,
    NOTIFICATION_DELETED,
    NOTIFICATION_MARKED_READ,
)

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("/", response_model=NotificationListResponse, status_code=status.HTTP_200_OK)
async def list_notifications(
    current_user: User = Depends(get_current_user),
) -> NotificationListResponse:
    """Return all notifications for the authenticated user with unread count."""
    return await get_notifications_service(current_user)


@router.patch("/{notification_id}/read", response_model=NotificationResponse, status_code=status.HTTP_200_OK)
async def mark_notification_read(
    notification_id: str,
    current_user: User = Depends(get_current_user),
) -> NotificationResponse:
    """Mark a single notification as read."""
    return await mark_as_read_service(current_user, notification_id)


@router.patch("/read-all", response_model=dict, status_code=status.HTTP_200_OK)
async def mark_all_notifications_read(
    current_user: User = Depends(get_current_user),
) -> dict:
    """Mark all notifications as read for the authenticated user."""
    result = await mark_all_as_read_service(current_user)
    return {"message": ALL_NOTIFICATIONS_MARKED_READ, **result}


@router.delete("/{notification_id}", response_model=dict, status_code=status.HTTP_200_OK)
async def delete_notification(
    notification_id: str,
    current_user: User = Depends(get_current_user),
) -> dict:
    """Soft-delete a notification by ID."""
    await delete_notification_service(current_user, notification_id)
    return {"message": NOTIFICATION_DELETED}
