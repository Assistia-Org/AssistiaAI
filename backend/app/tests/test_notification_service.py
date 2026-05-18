import unittest
from unittest.mock import patch, AsyncMock, MagicMock
from datetime import datetime, timezone
from fastapi import HTTPException

from app.services.notification_service import (
    create_notification_service,
    get_notifications_service,
    mark_as_read_service,
    mark_all_as_read_service,
    delete_notification_service,
)
from app.models.notification import NotificationType
from app.models.user import PersonalSettingsModel
from app.core.messages.error_message import NOTIFICATION_NOT_FOUND


class TestNotificationService(unittest.IsolatedAsyncioTestCase):
    """Test suite for Notification Service."""

    def setUp(self) -> None:
        """Set up mock models for testing."""
        self.mock_user = MagicMock()
        self.mock_user.id = "user123"
        self.mock_user.fcm_token = "fcm_token_123"
        self.mock_user.personal_settings = PersonalSettingsModel(notifications=True)

        self.mock_notification = MagicMock()
        self.mock_notification.id = "notification123"
        self.mock_notification._id = "notification123"
        self.mock_notification.user_id = "user123"
        self.mock_notification.type = NotificationType.GENERAL
        self.mock_notification.title = "Test Title"
        self.mock_notification.body = "Test Body"
        self.mock_notification.is_read = False
        self.mock_notification.metadata = None
        self.mock_notification.created_at = datetime.now(timezone.utc)

    @patch("app.services.notification_service.create_notification", new_callable=AsyncMock)
    @patch("app.services.notification_service.event_manager.publish", new_callable=AsyncMock)
    @patch("app.services.notification_service.get_user_by_id", new_callable=AsyncMock)
    @patch("app.services.notification_service.send_push_notification", new_callable=AsyncMock)
    async def test_create_notification_success(
        self,
        mock_send_push: AsyncMock,
        mock_get_user: AsyncMock,
        mock_publish: AsyncMock,
        mock_create: AsyncMock,
    ) -> None:
        """Test successful notification creation and real-time delivery."""
        mock_create.return_value = self.mock_notification
        mock_get_user.return_value = self.mock_user

        response = await create_notification_service(
            user_id="user123",
            type=NotificationType.GENERAL,
            title="Test Title",
            body="Test Body",
            metadata={"key": "val"},
        )

        self.assertEqual(response.id, "notification123")
        mock_create.assert_called_once_with(
            user_id="user123",
            type=NotificationType.GENERAL,
            title="Test Title",
            body="Test Body",
            metadata={"key": "val"},
        )
        mock_publish.assert_called_once()
        mock_get_user.assert_called_once_with("user123")
        mock_send_push.assert_called_once()

    @patch("app.services.notification_service.get_notifications_by_user", new_callable=AsyncMock)
    @patch("app.services.notification_service.count_unread", new_callable=AsyncMock)
    async def test_get_notifications_success(
        self, mock_count_unread: AsyncMock, mock_get_by_user: AsyncMock
    ) -> None:
        """Test listing notifications for user."""
        mock_get_by_user.return_value = [self.mock_notification]
        mock_count_unread.return_value = 1

        response = await get_notifications_service(self.mock_user)

        self.assertEqual(len(response.notifications), 1)
        self.assertEqual(response.unread_count, 1)
        mock_get_by_user.assert_called_once_with("user123")
        mock_count_unread.assert_called_once_with("user123")

    @patch("app.services.notification_service.get_notification_by_id", new_callable=AsyncMock)
    @patch("app.services.notification_service.mark_notification_as_read", new_callable=AsyncMock)
    async def test_mark_as_read_success(
        self, mock_mark_read: AsyncMock, mock_get_by_id: AsyncMock
    ) -> None:
        """Test marking a notification as read successfully."""
        mock_get_by_id.return_value = self.mock_notification
        
        # Mocking read update response
        updated_mock = MagicMock()
        updated_mock.id = "notification123"
        updated_mock._id = "notification123"
        updated_mock.user_id = "user123"
        updated_mock.type = NotificationType.GENERAL
        updated_mock.title = "Test Title"
        updated_mock.body = "Test Body"
        updated_mock.is_read = True
        updated_mock.metadata = None
        updated_mock.created_at = self.mock_notification.created_at
        
        mock_mark_read.return_value = updated_mock

        response = await mark_as_read_service(self.mock_user, "notification123")

        self.assertTrue(response.is_read)
        mock_get_by_id.assert_called_once_with("notification123")
        mock_mark_read.assert_called_once_with(self.mock_notification)

    @patch("app.services.notification_service.get_notification_by_id", new_callable=AsyncMock)
    async def test_mark_as_read_not_found(self, mock_get_by_id: AsyncMock) -> None:
        """Test marking read fails if notification doesn't exist."""
        mock_get_by_id.return_value = None

        with self.assertRaises(HTTPException) as ctx:
            await mark_as_read_service(self.mock_user, "nonexistent")

        self.assertEqual(ctx.exception.status_code, 404)
        self.assertEqual(ctx.exception.detail, NOTIFICATION_NOT_FOUND)

    @patch("app.services.notification_service.get_notification_by_id", new_callable=AsyncMock)
    async def test_mark_as_read_unauthorized(self, mock_get_by_id: AsyncMock) -> None:
        """Test marking read fails if notification is owned by a different user."""
        self.mock_notification.user_id = "other_user"
        mock_get_by_id.return_value = self.mock_notification

        with self.assertRaises(HTTPException) as ctx:
            await mark_as_read_service(self.mock_user, "notification123")

        self.assertEqual(ctx.exception.status_code, 404)
        self.assertEqual(ctx.exception.detail, NOTIFICATION_NOT_FOUND)

    @patch("app.services.notification_service.mark_all_notifications_as_read", new_callable=AsyncMock)
    async def test_mark_all_as_read_success(self, mock_mark_all: AsyncMock) -> None:
        """Test marking all notifications as read."""
        mock_mark_all.return_value = 5

        response = await mark_all_as_read_service(self.mock_user)

        self.assertEqual(response, {"updated_count": 5})
        mock_mark_all.assert_called_once_with("user123")

    @patch("app.services.notification_service.get_notification_by_id", new_callable=AsyncMock)
    @patch("app.services.notification_service.soft_delete_notification", new_callable=AsyncMock)
    async def test_delete_notification_success(
        self, mock_soft_delete: AsyncMock, mock_get_by_id: AsyncMock
    ) -> None:
        """Test successful notification soft-deletion."""
        mock_get_by_id.return_value = self.mock_notification

        await delete_notification_service(self.mock_user, "notification123")

        mock_get_by_id.assert_called_once_with("notification123")
        mock_soft_delete.assert_called_once_with(self.mock_notification)

    @patch("app.services.notification_service.get_notification_by_id", new_callable=AsyncMock)
    async def test_delete_notification_not_found(self, mock_get_by_id: AsyncMock) -> None:
        """Test soft deletion fails if notification doesn't exist."""
        mock_get_by_id.return_value = None

        with self.assertRaises(HTTPException) as ctx:
            await delete_notification_service(self.mock_user, "nonexistent")

        self.assertEqual(ctx.exception.status_code, 404)
        self.assertEqual(ctx.exception.detail, NOTIFICATION_NOT_FOUND)


if __name__ == "__main__":
    unittest.main()
