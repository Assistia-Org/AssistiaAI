import unittest
from unittest.mock import patch, AsyncMock, MagicMock
from datetime import datetime, timezone
from fastapi import HTTPException

from app.services.user_service import (
    get_user_service,
    get_user_by_email_service,
    list_users_service,
    update_user_service,
    update_me_service,
    delete_user_service,
    update_fcm_token_service,
)
from app.schemas.user import UserUpdate
from app.models.user import PersonalSettingsModel
from app.core.messages.error_message import USER_NOT_FOUND, DUPLICATE_EMAIL


class TestUserService(unittest.IsolatedAsyncioTestCase):
    """Test suite for User Service."""

    def setUp(self) -> None:
        """Set up standard mocked user attributes."""
        self.mock_user = MagicMock()
        self.mock_user.id = "user123"
        self.mock_user.username = "testuser"
        self.mock_user.display_name = "Test User"
        self.mock_user.email = "test@example.com"
        self.mock_user.avatar_url = "http://example.com/avatar.png"
        self.mock_user.joined_communities = []
        self.mock_user.personal_settings = PersonalSettingsModel(
            theme="light", notifications=True, language="tr"
        )
        self.mock_user.created_at = datetime.now(timezone.utc)
        self.mock_user.created_by = None
        self.mock_user.updated_at = None
        self.mock_user.updated_by = None
        self.mock_user.deleted_at = None
        self.mock_user.deleted_by = None
        self.mock_user.is_deleted = False

    @patch("app.services.user_service.get_user_by_id", new_callable=AsyncMock)
    async def test_get_user_success(self, mock_get_by_id: AsyncMock) -> None:
        """Test successful user retrieval by ID."""
        mock_get_by_id.return_value = self.mock_user

        response = await get_user_service("user123")

        self.assertEqual(response.id, "user123")
        self.assertEqual(response.username, "testuser")
        mock_get_by_id.assert_called_once_with("user123")

    @patch("app.services.user_service.get_user_by_id", new_callable=AsyncMock)
    async def test_get_user_not_found(self, mock_get_by_id: AsyncMock) -> None:
        """Test user retrieval fails when ID does not exist."""
        mock_get_by_id.return_value = None

        with self.assertRaises(HTTPException) as ctx:
            await get_user_service("nonexistent")

        self.assertEqual(ctx.exception.status_code, 404)
        self.assertEqual(ctx.exception.detail, USER_NOT_FOUND)

    @patch("app.services.user_service.get_user_by_email", new_callable=AsyncMock)
    async def test_get_user_by_email_success(self, mock_get_by_email: AsyncMock) -> None:
        """Test successful user retrieval by email."""
        mock_get_by_email.return_value = self.mock_user

        response = await get_user_by_email_service("test@example.com")

        self.assertEqual(response.email, "test@example.com")
        mock_get_by_email.assert_called_once_with("test@example.com")

    @patch("app.services.user_service.get_user_by_email", new_callable=AsyncMock)
    async def test_get_user_by_email_not_found(self, mock_get_by_email: AsyncMock) -> None:
        """Test user retrieval by email fails when email does not exist."""
        mock_get_by_email.return_value = None

        with self.assertRaises(HTTPException) as ctx:
            await get_user_by_email_service("nonexistent@example.com")

        self.assertEqual(ctx.exception.status_code, 404)
        self.assertEqual(ctx.exception.detail, USER_NOT_FOUND)

    @patch("app.services.user_service.list_users", new_callable=AsyncMock)
    async def test_list_users_success(self, mock_list_users: AsyncMock) -> None:
        """Test listing users returns list of user schemas."""
        mock_list_users.return_value = [self.mock_user]

        response = await list_users_service()

        self.assertEqual(len(response), 1)
        self.assertEqual(response[0].id, "user123")
        mock_list_users.assert_called_once()

    @patch("app.services.user_service.get_user_by_id", new_callable=AsyncMock)
    @patch("app.services.user_service.get_user_by_email", new_callable=AsyncMock)
    @patch("app.services.user_service.update_user", new_callable=AsyncMock)
    @patch("app.services.user_service.set_redis_value", new_callable=AsyncMock)
    @patch("app.services.user_service.logger")
    async def test_update_user_success(
        self,
        mock_logger: MagicMock,
        mock_set_redis: AsyncMock,
        mock_update_user: AsyncMock,
        mock_get_by_email: AsyncMock,
        mock_get_by_id: AsyncMock,
    ) -> None:
        """Test successful update of user details."""
        mock_get_by_id.return_value = self.mock_user
        mock_get_by_email.return_value = None
        mock_update_user.return_value = self.mock_user
        
        mock_logger.info = AsyncMock()

        update_data = UserUpdate(display_name="New Name", email="new@example.com")
        response = await update_user_service("user123", update_data)

        self.assertEqual(response.id, "user123")
        mock_get_by_id.assert_called_once_with("user123")
        mock_get_by_email.assert_called_once_with("new@example.com")
        mock_update_user.assert_called_once()
        mock_set_redis.assert_called_once()
        mock_logger.info.assert_called_once()

    @patch("app.services.user_service.get_user_by_id", new_callable=AsyncMock)
    async def test_update_user_not_found(self, mock_get_by_id: AsyncMock) -> None:
        """Test updating non-existent user fails."""
        mock_get_by_id.return_value = None

        with self.assertRaises(HTTPException) as ctx:
            await update_user_service("nonexistent", UserUpdate(display_name="Test"))

        self.assertEqual(ctx.exception.status_code, 404)
        self.assertEqual(ctx.exception.detail, USER_NOT_FOUND)

    @patch("app.services.user_service.get_user_by_id", new_callable=AsyncMock)
    @patch("app.services.user_service.get_user_by_email", new_callable=AsyncMock)
    async def test_update_user_duplicate_email(
        self, mock_get_by_email: AsyncMock, mock_get_by_id: AsyncMock
    ) -> None:
        """Test updating user to an already registered email fails."""
        mock_get_by_id.return_value = self.mock_user

        # Create another user representing duplicate email owner
        other_user = MagicMock()
        other_user.id = "user456"
        other_user.email = "duplicate@example.com"
        mock_get_by_email.return_value = other_user

        update_data = UserUpdate(email="duplicate@example.com")

        with self.assertRaises(HTTPException) as ctx:
            await update_user_service("user123", update_data)

        self.assertEqual(ctx.exception.status_code, 400)
        self.assertEqual(ctx.exception.detail, DUPLICATE_EMAIL)

    @patch("app.services.user_service.update_user_service", new_callable=AsyncMock)
    async def test_update_me_service(self, mock_update_user_service: AsyncMock) -> None:
        """Test update_me_service delegates correctly."""
        update_data = UserUpdate(display_name="Me")
        await update_me_service("user123", update_data)
        mock_update_service = mock_update_user_service
        mock_update_service.assert_called_once_with("user123", update_data)

    @patch("app.services.user_service.get_user_by_id", new_callable=AsyncMock)
    @patch("app.services.user_service.delete_user", new_callable=AsyncMock)
    @patch("app.services.user_service.logger")
    async def test_delete_user_success(
        self, mock_logger: MagicMock, mock_delete_user: AsyncMock, mock_get_by_id: AsyncMock
    ) -> None:
        """Test successful user deletion."""
        mock_get_by_id.return_value = self.mock_user
        mock_logger.warning = AsyncMock()

        await delete_user_service("user123")

        mock_get_by_id.assert_called_once_with("user123")
        mock_delete_user.assert_called_once_with(self.mock_user)
        mock_logger.warning.assert_called_once()

    @patch("app.services.user_service.get_user_by_id", new_callable=AsyncMock)
    async def test_delete_user_not_found(self, mock_get_by_id: AsyncMock) -> None:
        """Test deleting non-existent user fails."""
        mock_get_by_id.return_value = None

        with self.assertRaises(HTTPException) as ctx:
            await delete_user_service("nonexistent")

        self.assertEqual(ctx.exception.status_code, 404)
        self.assertEqual(ctx.exception.detail, USER_NOT_FOUND)

    @patch("app.services.user_service.update_fcm_token", new_callable=AsyncMock)
    async def test_update_fcm_token_success(self, mock_update_fcm: AsyncMock) -> None:
        """Test successful update of FCM push token."""
        mock_update_fcm.return_value = True

        await update_fcm_token_service("user123", "token123")

        mock_update_fcm.assert_called_once_with("user123", "token123")

    @patch("app.services.user_service.update_fcm_token", new_callable=AsyncMock)
    async def test_update_fcm_token_not_found(self, mock_update_fcm: AsyncMock) -> None:
        """Test FCM token update fails if user is not found."""
        mock_update_fcm.return_value = False

        with self.assertRaises(HTTPException) as ctx:
            await update_fcm_token_service("nonexistent", "token123")

        self.assertEqual(ctx.exception.status_code, 404)
        self.assertEqual(ctx.exception.detail, USER_NOT_FOUND)


if __name__ == "__main__":
    unittest.main()
