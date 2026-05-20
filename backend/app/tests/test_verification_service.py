import unittest
from unittest.mock import patch, AsyncMock, MagicMock
from fastapi import HTTPException

from app.services.verification_service import (
    generate_code,
    request_verification_service,
    verify_code_service,
)
from app.core.messages.error_message import (
    TOO_MANY_VERIFICATION_REQUESTS,
    INVALID_VERIFICATION_CODE,
    EMAIL_SEND_FAILED,
    DUPLICATE_EMAIL,
)
from app.core.messages.success_message import (
    VERIFICATION_CODE_SENT,
    EMAIL_VERIFIED,
)


class TestVerificationService(unittest.IsolatedAsyncioTestCase):
    """Test suite for Verification Service."""

    def test_generate_code(self) -> None:
        """Test numeric code generator length and character constraints."""
        code_6 = generate_code()
        self.assertEqual(len(code_6), 6)
        self.assertTrue(code_6.isdigit())

        code_8 = generate_code(length=8)
        self.assertEqual(len(code_8), 8)
        self.assertTrue(code_8.isdigit())

    @patch("app.services.verification_service.get_user_by_email", new_callable=AsyncMock)
    @patch("app.services.verification_service.increment_redis_value", new_callable=AsyncMock)
    @patch("app.services.verification_service.set_redis_value", new_callable=AsyncMock)
    @patch("app.services.verification_service.send_verification_code_email")
    async def test_request_verification_success(
        self,
        mock_send_email: MagicMock,
        mock_set_redis: AsyncMock,
        mock_increment_redis: AsyncMock,
        mock_get_user: AsyncMock,
    ) -> None:
        """Test successful verification request happy path."""
        mock_get_user.return_value = None
        mock_increment_redis.return_value = 1
        mock_send_email.return_value = True

        email = "test@example.com"
        response = await request_verification_service(email)

        self.assertEqual(response, VERIFICATION_CODE_SENT)
        mock_get_user.assert_called_once_with(email)
        mock_increment_redis.assert_called_once()
        mock_set_redis.assert_called_once()
        mock_send_email.assert_called_once()

    @patch("app.services.verification_service.get_user_by_email", new_callable=AsyncMock)
    async def test_request_verification_duplicate_email(self, mock_get_user: AsyncMock) -> None:
        """Test verification request fails when email is already registered."""
        mock_user = MagicMock()
        mock_get_user.return_value = mock_user

        with self.assertRaises(HTTPException) as ctx:
            await request_verification_service("test@example.com")

        self.assertEqual(ctx.exception.status_code, 409)
        self.assertEqual(ctx.exception.detail, DUPLICATE_EMAIL)

    @patch("app.services.verification_service.get_user_by_email", new_callable=AsyncMock)
    @patch("app.services.verification_service.increment_redis_value", new_callable=AsyncMock)
    async def test_request_verification_rate_limited(
        self, mock_increment_redis: AsyncMock, mock_get_user: AsyncMock
    ) -> None:
        """Test verification request fails when rate limit is exceeded."""
        mock_get_user.return_value = None
        mock_increment_redis.return_value = 4  # Exceeds the limit of 3

        with self.assertRaises(HTTPException) as ctx:
            await request_verification_service("test@example.com")

        self.assertEqual(ctx.exception.status_code, 429)
        self.assertEqual(ctx.exception.detail, TOO_MANY_VERIFICATION_REQUESTS)

    @patch("app.services.verification_service.get_user_by_email", new_callable=AsyncMock)
    @patch("app.services.verification_service.increment_redis_value", new_callable=AsyncMock)
    @patch("app.services.verification_service.set_redis_value", new_callable=AsyncMock)
    @patch("app.services.verification_service.send_verification_code_email")
    async def test_request_verification_email_send_failed(
        self,
        mock_send_email: MagicMock,
        mock_set_redis: AsyncMock,
        mock_increment_redis: AsyncMock,
        mock_get_user: AsyncMock,
    ) -> None:
        """Test verification request fails when SMTP/Resend fails to send email."""
        mock_get_user.return_value = None
        mock_increment_redis.return_value = 1
        mock_send_email.return_value = False  # Failed to send

        with self.assertRaises(HTTPException) as ctx:
            await request_verification_service("test@example.com")

        self.assertEqual(ctx.exception.status_code, 500)
        self.assertEqual(ctx.exception.detail, EMAIL_SEND_FAILED)

    @patch("app.services.verification_service.get_redis_value", new_callable=AsyncMock)
    @patch("app.services.verification_service.delete_redis_value", new_callable=AsyncMock)
    async def test_verify_code_success(
        self, mock_delete_redis: AsyncMock, mock_get_redis: AsyncMock
    ) -> None:
        """Test successful verification of code."""
        mock_get_redis.return_value = "123456"

        email = "test@example.com"
        response = await verify_code_service(email, "123456")

        self.assertEqual(response, EMAIL_VERIFIED)
        mock_delete_redis.assert_called_once_with(f"verification:code:{email}")

    @patch("app.services.verification_service.get_redis_value", new_callable=AsyncMock)
    async def test_verify_code_not_found(self, mock_get_redis: AsyncMock) -> None:
        """Test verification fails when code is not in Redis (expired/not requested)."""
        mock_get_redis.return_value = None

        with self.assertRaises(HTTPException) as ctx:
            await verify_code_service("test@example.com", "123456")

        self.assertEqual(ctx.exception.status_code, 400)
        self.assertEqual(ctx.exception.detail, INVALID_VERIFICATION_CODE)

    @patch("app.services.verification_service.get_redis_value", new_callable=AsyncMock)
    async def test_verify_code_mismatch(self, mock_get_redis: MagicMock) -> None:
        """Test verification fails when input code doesn't match stored code."""
        mock_get_redis.return_value = "123456"

        with self.assertRaises(HTTPException) as ctx:
            await verify_code_service("test@example.com", "654321")

        self.assertEqual(ctx.exception.status_code, 400)
        self.assertEqual(ctx.exception.detail, INVALID_VERIFICATION_CODE)


if __name__ == "__main__":
    unittest.main()
