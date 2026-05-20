import pytest
import httpx
from app.models.user import User as UserModel
from app.models.notification import Notification, NotificationType

pytestmark = pytest.mark.asyncio

async def test_list_notifications(
    async_client: httpx.AsyncClient,
    auth_headers: dict
) -> None:
    """Test retrieving list of notifications for currently authenticated user."""
    db_user = await UserModel.find_one(UserModel.email == "integrationtest@example.com")
    assert db_user is not None

    # 1. Create a notification directly in DB
    notification = Notification(
        user_id=str(db_user.id),
        type=NotificationType.GENERAL,
        title="Welcome Notification",
        body="Welcome to our platform!"
    )
    await notification.save()

    # 2. Get notifications list
    response = await async_client.get(
        "/api/v1/notifications/",
        headers=auth_headers
    )
    assert response.status_code == 200
    json_data = response.json()
    assert json_data["unread_count"] == 1
    assert len(json_data["notifications"]) >= 1
    assert json_data["notifications"][0]["title"] == "Welcome Notification"

async def test_mark_notification_read(
    async_client: httpx.AsyncClient,
    auth_headers: dict
) -> None:
    """Test marking a specific notification as read."""
    db_user = await UserModel.find_one(UserModel.email == "integrationtest@example.com")

    notification = Notification(
        user_id=str(db_user.id),
        type=NotificationType.GENERAL,
        title="Unread Alert",
        body="Important updates"
    )
    await notification.save()

    # Mark read
    response = await async_client.patch(
        f"/api/v1/notifications/{notification.id}/read",
        headers=auth_headers
    )
    assert response.status_code == 200
    assert response.json()["is_read"] is True

    # Verify in DB
    db_notif = await Notification.get(notification.id)
    assert db_notif.is_read is True

async def test_mark_all_notifications_read(
    async_client: httpx.AsyncClient,
    auth_headers: dict
) -> None:
    """Test marking all notifications as read for current user."""
    db_user = await UserModel.find_one(UserModel.email == "integrationtest@example.com")

    # Create 2 unread notifications
    await Notification(user_id=str(db_user.id), type=NotificationType.GENERAL, title="A", body="A").save()
    await Notification(user_id=str(db_user.id), type=NotificationType.GENERAL, title="B", body="B").save()

    # Mark all read
    response = await async_client.patch(
        "/api/v1/notifications/read-all",
        headers=auth_headers
    )
    assert response.status_code == 200
    assert response.json()["updated_count"] >= 2

    # Verify all are read
    unread = await Notification.find(Notification.user_id == str(db_user.id), Notification.is_read == False).to_list()
    assert len(unread) == 0

async def test_delete_notification(
    async_client: httpx.AsyncClient,
    auth_headers: dict
) -> None:
    """Test soft/hard deleting notification."""
    db_user = await UserModel.find_one(UserModel.email == "integrationtest@example.com")

    notification = Notification(
        user_id=str(db_user.id),
        type=NotificationType.GENERAL,
        title="Delete me",
        body="Soon to be gone"
    )
    await notification.save()

    # Delete
    response = await async_client.delete(
        f"/api/v1/notifications/{notification.id}",
        headers=auth_headers
    )
    assert response.status_code == 200
    assert response.json()["message"] == "Notification deleted successfully."

    # Verify no longer returned or soft deleted
    db_notif = await Notification.get(notification.id)
    assert db_notif is not None
    assert db_notif.is_deleted is True
