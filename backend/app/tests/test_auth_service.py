import unittest
from unittest.mock import patch, AsyncMock, MagicMock
from datetime import datetime, timedelta, timezone
from fastapi import HTTPException

from app.services.auth_service import (
    change_password_service,
    forgot_password_service,
    reset_password_service,
    register_user_service,
    login_service,
    refresh_token_service,
    google_auth_service,
)
from app.models.user import PersonalSettingsModel
from app.schemas.auth import (
    ChangePasswordRequest,
    ForgotPasswordRequest,
    ResetPasswordRequest,
    LoginSchema,
    TokenRefresh,
    GoogleAuthRequest,
)
from app.schemas.user import UserCreate
from app.core.messages.error_message import (
    DUPLICATE_EMAIL,
    INCORRECT_EMAIL_OR_PASSWORD,
    INVALID_REFRESH_TOKEN,
    USER_NOT_FOUND,
    INVALID_OR_EXPIRED_TOKEN,
    EMAIL_SEND_FAILED,
    INCORRECT_CURRENT_PASSWORD,
    INVALID_GOOGLE_TOKEN,
    GOOGLE_AUTH_FAILED,
)
from app.core.messages.success_message import (
    PASSWORD_RESET_EMAIL_SENT,
    PASSWORD_RESET_SUCCESS,
    PASSWORD_CHANGED,
)


class TestAuthService(unittest.IsolatedAsyncioTestCase):
    """Test suite for Auth Service."""

    def setUp(self) -> None:
        """Set up mocked user and standard inputs."""
        self.mock_user = MagicMock()
        self.mock_user.id = "user123"
        self.mock_user.username = "testuser"
        self.mock_user.display_name = "Test User"
        self.mock_user.email = "test@example.com"
        self.mock_user.hashed_password = "hashed_current_password"
        self.mock_user.avatar_url = None
        self.mock_user.joined_communities = []
        self.mock_user.personal_settings = PersonalSettingsModel()
        self.mock_user.created_at = datetime.now(timezone.utc)
        self.mock_user.created_by = None
        self.mock_user.updated_at = None
        self.mock_user.updated_by = None
        self.mock_user.deleted_at = None
        self.mock_user.deleted_by = None
        self.mock_user.is_deleted = False
        self.mock_user.save = AsyncMock()

    @patch("app.services.auth_service.verify_password")
    @patch("app.services.auth_service.get_password_hash")
    @patch("app.services.auth_service.validate_password_strength")
    @patch("app.services.auth_service.logger")
    async def test_change_password_success(
        self,
        mock_logger: MagicMock,
        mock_validate: MagicMock,
        mock_hash: MagicMock,
        mock_verify: MagicMock,
    ) -> None:
        """Test successful password change happy path."""
        mock_verify.return_value = True
        mock_hash.return_value = "new_hashed_password"
        mock_logger.info = AsyncMock()

        data = ChangePasswordRequest(
            current_password="OldPassword123",
            new_password="NewPassword123",
            confirm_password="NewPassword123",
        )

        response = await change_password_service(self.mock_user, data)

        self.assertEqual(response, {"message": PASSWORD_CHANGED})
        self.assertEqual(self.mock_user.hashed_password, "new_hashed_password")
        mock_verify.assert_called_once()
        mock_validate.assert_called_once_with("NewPassword123")
        self.mock_user.save.assert_called_once()
        mock_logger.info.assert_called_once()

    @patch("app.services.auth_service.verify_password")
    async def test_change_password_incorrect_current(self, mock_verify: MagicMock) -> None:
        """Test password change fails with incorrect current password."""
        mock_verify.return_value = False

        data = ChangePasswordRequest(
            current_password="WrongOldPassword",
            new_password="NewPassword123",
            confirm_password="NewPassword123",
        )

        with self.assertRaises(HTTPException) as ctx:
            await change_password_service(self.mock_user, data)

        self.assertEqual(ctx.exception.status_code, 400)
        self.assertEqual(ctx.exception.detail, INCORRECT_CURRENT_PASSWORD)

    @patch("app.services.auth_service.verify_password")
    async def test_change_password_mismatched_confirm(self, mock_verify: MagicMock) -> None:
        """Test password change fails with mismatched confirm password."""
        mock_verify.return_value = True
        data = ChangePasswordRequest(
            current_password="OldPassword123",
            new_password="NewPassword123",
            confirm_password="DifferentNewPassword123",
        )

        with self.assertRaises(HTTPException) as ctx:
            await change_password_service(self.mock_user, data)

        self.assertEqual(ctx.exception.status_code, 400)

    @patch("app.services.auth_service.get_user_by_email", new_callable=AsyncMock)
    @patch("app.services.auth_service.send_password_reset_email")
    @patch("app.services.auth_service.logger")
    async def test_forgot_password_success(
        self, mock_logger: MagicMock, mock_send_email: MagicMock, mock_get_user: AsyncMock
    ) -> None:
        """Test successful forgot password request."""
        mock_get_user.return_value = self.mock_user
        mock_send_email.return_value = True
        mock_logger.info = AsyncMock()

        data = ForgotPasswordRequest(email="test@example.com")
        response = await forgot_password_service(data)

        self.assertEqual(response, {"message": PASSWORD_RESET_EMAIL_SENT})
        self.assertIsNotNone(self.mock_user.reset_token)
        self.assertIsNotNone(self.mock_user.reset_token_expires_at)
        self.mock_user.save.assert_called_once()
        mock_send_email.assert_called_once()
        mock_logger.info.assert_called_once()

    @patch("app.services.auth_service.get_user_by_email", new_callable=AsyncMock)
    async def test_forgot_password_user_not_found(self, mock_get_user: AsyncMock) -> None:
        """Test forgot password fails for non-registered email."""
        mock_get_user.return_value = None

        data = ForgotPasswordRequest(email="nonexistent@example.com")
        with self.assertRaises(HTTPException) as ctx:
            await forgot_password_service(data)

        self.assertEqual(ctx.exception.status_code, 404)
        self.assertEqual(ctx.exception.detail, USER_NOT_FOUND)

    @patch("app.services.auth_service.get_user_by_email", new_callable=AsyncMock)
    @patch("app.services.auth_service.send_password_reset_email")
    async def test_forgot_password_email_send_failed(
        self, mock_send_email: MagicMock, mock_get_user: AsyncMock
    ) -> None:
        """Test forgot password fails if email sending fails."""
        mock_get_user.return_value = self.mock_user
        mock_send_email.return_value = False

        data = ForgotPasswordRequest(email="test@example.com")
        with self.assertRaises(HTTPException) as ctx:
            await forgot_password_service(data)

        self.assertEqual(ctx.exception.status_code, 500)
        self.assertEqual(ctx.exception.detail, EMAIL_SEND_FAILED)

    @patch("app.services.auth_service.get_user_by_reset_token", new_callable=AsyncMock)
    @patch("app.services.auth_service.get_password_hash")
    @patch("app.services.auth_service.validate_password_strength")
    async def test_reset_password_success(
        self, mock_validate: MagicMock, mock_hash: MagicMock, mock_get_by_token: AsyncMock
    ) -> None:
        """Test successful password reset using token."""
        self.mock_user.reset_token = "token123"
        self.mock_user.reset_token_expires_at = datetime.now(timezone.utc) + timedelta(hours=1)
        mock_get_by_token.return_value = self.mock_user
        mock_hash.return_value = "new_hashed_password"

        data = ResetPasswordRequest(
            token="token123",
            new_password="NewPassword123",
            confirm_password="NewPassword123",
        )

        response = await reset_password_service(data)

        self.assertEqual(response, {"message": PASSWORD_RESET_SUCCESS})
        self.assertEqual(self.mock_user.hashed_password, "new_hashed_password")
        self.assertIsNone(self.mock_user.reset_token)
        self.assertIsNone(self.mock_user.reset_token_expires_at)
        self.mock_user.save.assert_called_once()

    @patch("app.services.auth_service.get_user_by_reset_token", new_callable=AsyncMock)
    async def test_reset_password_invalid_token(self, mock_get_by_token: AsyncMock) -> None:
        """Test password reset fails with invalid token."""
        mock_get_by_token.return_value = None

        data = ResetPasswordRequest(
            token="invalid_token",
            new_password="NewPassword123",
            confirm_password="NewPassword123",
        )

        with self.assertRaises(HTTPException) as ctx:
            await reset_password_service(data)

        self.assertEqual(ctx.exception.status_code, 400)
        self.assertEqual(ctx.exception.detail, INVALID_OR_EXPIRED_TOKEN)

    @patch("app.services.auth_service.get_user_by_reset_token", new_callable=AsyncMock)
    async def test_reset_password_expired_token(self, mock_get_by_token: AsyncMock) -> None:
        """Test password reset fails with expired token."""
        self.mock_user.reset_token = "token123"
        # Set expiry to past
        self.mock_user.reset_token_expires_at = datetime.now(timezone.utc) - timedelta(hours=1)
        mock_get_by_token.return_value = self.mock_user

        data = ResetPasswordRequest(
            token="token123",
            new_password="NewPassword123",
            confirm_password="NewPassword123",
        )

        with self.assertRaises(HTTPException) as ctx:
            await reset_password_service(data)

        self.assertEqual(ctx.exception.status_code, 400)
        self.assertEqual(ctx.exception.detail, INVALID_OR_EXPIRED_TOKEN)

    @patch("app.services.auth_service.get_user_by_email", new_callable=AsyncMock)
    @patch("app.services.auth_service.create_user", new_callable=AsyncMock)
    @patch("app.services.auth_service.get_password_hash")
    @patch("app.services.auth_service.validate_password_strength")
    @patch("app.services.auth_service._cache_user", new_callable=AsyncMock)
    @patch("app.services.auth_service.logger")
    async def test_register_user_success(
        self,
        mock_logger: MagicMock,
        mock_cache: AsyncMock,
        mock_validate: MagicMock,
        mock_hash: MagicMock,
        mock_create: AsyncMock,
        mock_get_user: AsyncMock,
    ) -> None:
        """Test successful registration happy path."""
        mock_get_user.return_value = None
        mock_hash.return_value = "hashed_password"
        mock_create.return_value = self.mock_user
        mock_logger.info = AsyncMock()

        data = UserCreate(
            username="testuser",
            display_name="Test User",
            email="test@example.com",
            password="Password123",
        )

        response = await register_user_service(data)

        self.assertEqual(response.id, "user123")
        mock_validate.assert_called_once_with("Password123")
        mock_get_user.assert_called_once_with("test@example.com")
        mock_create.assert_called_once()
        mock_cache.assert_called_once_with(self.mock_user)
        mock_logger.info.assert_called_once()

    @patch("app.services.auth_service.get_user_by_email", new_callable=AsyncMock)
    @patch("app.services.auth_service.validate_password_strength")
    async def test_register_user_duplicate_email(
        self, mock_validate: MagicMock, mock_get_user: AsyncMock
    ) -> None:
        """Test registration fails with duplicate email."""
        mock_get_user.return_value = self.mock_user

        data = UserCreate(
            username="testuser",
            display_name="Test User",
            email="test@example.com",
            password="Password123",
        )

        with self.assertRaises(HTTPException) as ctx:
            await register_user_service(data)

        self.assertEqual(ctx.exception.status_code, 400)
        self.assertEqual(ctx.exception.detail, DUPLICATE_EMAIL)

    @patch("app.services.auth_service.get_user_by_email", new_callable=AsyncMock)
    @patch("app.services.auth_service.verify_password")
    @patch("app.services.auth_service.create_access_token")
    @patch("app.services.auth_service.create_refresh_token")
    @patch("app.services.auth_service._cache_user", new_callable=AsyncMock)
    @patch("app.services.auth_service.logger")
    async def test_login_success(
        self,
        mock_logger: MagicMock,
        mock_cache: AsyncMock,
        mock_create_refresh: MagicMock,
        mock_create_access: MagicMock,
        mock_verify: MagicMock,
        mock_get_user: AsyncMock,
    ) -> None:
        """Test successful login happy path."""
        mock_get_user.return_value = self.mock_user
        mock_verify.return_value = True
        mock_create_access.return_value = "access_token_123"
        mock_create_refresh.return_value = "refresh_token_123"
        mock_logger.info = AsyncMock()

        data = LoginSchema(email="test@example.com", password="Password123")

        response = await login_service(data)

        self.assertEqual(response.access_token, "access_token_123")
        self.assertEqual(response.refresh_token, "refresh_token_123")
        mock_get_user.assert_called_once_with("test@example.com")
        mock_verify.assert_called_once_with("Password123", self.mock_user.hashed_password)
        mock_cache.assert_called_once_with(self.mock_user)
        mock_logger.info.assert_called_once()

    @patch("app.services.auth_service.get_user_by_email", new_callable=AsyncMock)
    @patch("app.services.auth_service.logger")
    async def test_login_user_not_found(self, mock_logger: MagicMock, mock_get_user: AsyncMock) -> None:
        """Test login fails when email not registered."""
        mock_get_user.return_value = None
        mock_logger.warning = AsyncMock()

        data = LoginSchema(email="nonexistent@example.com", password="Password123")

        with self.assertRaises(HTTPException) as ctx:
            await login_service(data)

        self.assertEqual(ctx.exception.status_code, 401)
        self.assertEqual(ctx.exception.detail, INCORRECT_EMAIL_OR_PASSWORD)
        mock_logger.warning.assert_called_once()

    @patch("app.services.auth_service.get_user_by_email", new_callable=AsyncMock)
    @patch("app.services.auth_service.verify_password")
    @patch("app.services.auth_service.logger")
    async def test_login_incorrect_password(
        self, mock_logger: MagicMock, mock_verify: MagicMock, mock_get_user: AsyncMock
    ) -> None:
        """Test login fails with incorrect password."""
        mock_get_user.return_value = self.mock_user
        mock_verify.return_value = False
        mock_logger.warning = AsyncMock()

        data = LoginSchema(email="test@example.com", password="WrongPassword")

        with self.assertRaises(HTTPException) as ctx:
            await login_service(data)

        self.assertEqual(ctx.exception.status_code, 401)
        self.assertEqual(ctx.exception.detail, INCORRECT_EMAIL_OR_PASSWORD)
        mock_logger.warning.assert_called_once()

    @patch("app.services.auth_service.jwt.decode")
    @patch("app.services.auth_service.get_user_by_id", new_callable=AsyncMock)
    @patch("app.services.auth_service.create_access_token")
    @patch("app.services.auth_service.create_refresh_token")
    @patch("app.services.auth_service.logger")
    async def test_refresh_token_success(
        self,
        mock_logger: MagicMock,
        mock_create_refresh: MagicMock,
        mock_create_access: MagicMock,
        mock_get_user: AsyncMock,
        mock_jwt_decode: MagicMock,
    ) -> None:
        """Test successful token refresh happy path."""
        mock_jwt_decode.return_value = {
            "sub": "user123",
            "type": "refresh",
        }
        mock_get_user.return_value = self.mock_user
        mock_create_access.return_value = "new_access_token"
        mock_create_refresh.return_value = "new_refresh_token"
        mock_logger.info = AsyncMock()

        data = TokenRefresh(refresh_token="old_refresh_token")

        response = await refresh_token_service(data)

        self.assertEqual(response.access_token, "new_access_token")
        self.assertEqual(response.refresh_token, "new_refresh_token")
        mock_jwt_decode.assert_called_once()
        mock_get_user.assert_called_once_with("user123")
        mock_logger.info.assert_called_once()

    @patch("app.services.auth_service.jwt.decode")
    async def test_refresh_token_invalid_payload_type(self, mock_jwt_decode: MagicMock) -> None:
        """Test refresh token fails if decrypted payload is not type: refresh."""
        mock_jwt_decode.return_value = {
            "sub": "user123",
            "type": "access",  # invalid
        }

        data = TokenRefresh(refresh_token="access_token_passed_as_refresh")

        with self.assertRaises(HTTPException) as ctx:
            await refresh_token_service(data)

        self.assertEqual(ctx.exception.status_code, 401)
        self.assertEqual(ctx.exception.detail, INVALID_REFRESH_TOKEN)

    @patch("app.services.auth_service.firebase_auth.verify_id_token")
    @patch("app.services.auth_service.get_user_by_google_id", new_callable=AsyncMock)
    @patch("app.services.auth_service.create_access_token")
    @patch("app.services.auth_service.create_refresh_token")
    @patch("app.services.auth_service._cache_user", new_callable=AsyncMock)
    @patch("app.services.auth_service.logger")
    async def test_google_auth_existing_user(
        self,
        mock_logger: MagicMock,
        mock_cache: AsyncMock,
        mock_create_refresh: MagicMock,
        mock_create_access: MagicMock,
        mock_get_google: AsyncMock,
        mock_firebase_auth: MagicMock,
    ) -> None:
        """Test successful Google Sign-In login for existing user."""
        mock_firebase_auth.return_value = {
            "uid": "google123",
            "email": "test@example.com",
            "name": "Google User",
            "picture": "http://google.com/pic.png",
        }
        mock_get_google.return_value = self.mock_user
        mock_create_access.return_value = "access_token"
        mock_create_refresh.return_value = "refresh_token"
        mock_logger.info = AsyncMock()

        data = GoogleAuthRequest(id_token="google_id_token", fcm_token="new_fcm_token")

        response = await google_auth_service(data)

        self.assertEqual(response.access_token, "access_token")
        self.assertEqual(self.mock_user.fcm_token, "new_fcm_token")
        mock_firebase_auth.assert_called_once_with("google_id_token")
        mock_get_google.assert_called_once_with("google123")
        mock_cache.assert_called_once_with(self.mock_user)
        self.mock_user.save.assert_called_once()
        mock_logger.info.assert_called_once()


if __name__ == "__main__":
    unittest.main()
