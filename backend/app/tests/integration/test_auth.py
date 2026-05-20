import pytest
import httpx
from app.core.messages.error_message import (
    DUPLICATE_EMAIL,
    INCORRECT_EMAIL_OR_PASSWORD,
    INVALID_REFRESH_TOKEN,
    INCORRECT_CURRENT_PASSWORD,
)

pytestmark = pytest.mark.asyncio

async def test_register_user_success(async_client: httpx.AsyncClient) -> None:
    """Test successful user registration flow."""
    user_data = {
        "username": "newuser",
        "display_name": "New User",
        "email": "newuser@example.com",
        "password": "Password123"
    }
    response = await async_client.post("/api/v1/auth/register", json=user_data)
    assert response.status_code == 201
    json_data = response.json()
    assert json_data["username"] == "newuser"
    assert json_data["email"] == "newuser@example.com"
    assert "id" in json_data

async def test_register_user_duplicate_email(async_client: httpx.AsyncClient, registered_user: dict) -> None:
    """Test user registration fails when email is already registered."""
    duplicate_data = {
        "username": "duplicateuser",
        "display_name": "Duplicate User",
        "email": registered_user["email"],
        "password": "Password123"
    }
    response = await async_client.post("/api/v1/auth/register", json=duplicate_data)
    assert response.status_code == 400
    assert response.json()["detail"] == DUPLICATE_EMAIL

async def test_login_user_success(async_client: httpx.AsyncClient, registered_user: dict) -> None:
    """Test successful login with registered credentials."""
    login_data = {
        "email": registered_user["email"],
        "password": registered_user["password"]
    }
    response = await async_client.post("/api/v1/auth/login", json=login_data)
    assert response.status_code == 200
    json_data = response.json()
    assert "access_token" in json_data
    assert "refresh_token" in json_data
    assert json_data["token_type"] == "bearer"

async def test_login_user_incorrect_credentials(async_client: httpx.AsyncClient, registered_user: dict) -> None:
    """Test login failure with incorrect credentials."""
    login_data = {
        "email": registered_user["email"],
        "password": "WrongPassword123"
    }
    response = await async_client.post("/api/v1/auth/login", json=login_data)
    assert response.status_code == 401
    assert response.json()["detail"] == INCORRECT_EMAIL_OR_PASSWORD

async def test_token_refresh_success(async_client: httpx.AsyncClient, registered_user: dict) -> None:
    """Test successful token refresh using a valid refresh token."""
    # 1. Login to get refresh token
    login_data = {
        "email": registered_user["email"],
        "password": registered_user["password"]
    }
    login_res = await async_client.post("/api/v1/auth/login", json=login_data)
    refresh_token = login_res.json()["refresh_token"]

    # 2. Call refresh endpoint
    refresh_res = await async_client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": refresh_token}
    )
    assert refresh_res.status_code == 200
    assert "access_token" in refresh_res.json()
    assert "refresh_token" in refresh_res.json()

async def test_token_refresh_invalid_token(async_client: httpx.AsyncClient) -> None:
    """Test token refresh failure when using an invalid refresh token."""
    response = await async_client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": "invalid_refresh_token_string"}
    )
    assert response.status_code == 401
    assert response.json()["detail"] == INVALID_REFRESH_TOKEN

async def test_change_password_success(
    async_client: httpx.AsyncClient,
    registered_user: dict,
    auth_headers: dict
) -> None:
    """Test successful password change for an authenticated user."""
    change_data = {
        "current_password": registered_user["password"],
        "new_password": "NewSecurePassword123",
        "confirm_password": "NewSecurePassword123"
    }
    response = await async_client.post(
        "/api/v1/auth/change-password",
        json=change_data,
        headers=auth_headers
    )
    assert response.status_code == 200
    assert "message" in response.json()

    # Verify logging in with new password works
    login_data = {
        "email": registered_user["email"],
        "password": "NewSecurePassword123"
    }
    login_res = await async_client.post("/api/v1/auth/login", json=login_data)
    assert login_res.status_code == 200

async def test_change_password_incorrect_current(
    async_client: httpx.AsyncClient,
    auth_headers: dict
) -> None:
    """Test password change failure when current password is incorrect."""
    change_data = {
        "current_password": "WrongPassword123",
        "new_password": "NewSecurePassword123",
        "confirm_password": "NewSecurePassword123"
    }
    response = await async_client.post(
        "/api/v1/auth/change-password",
        json=change_data,
        headers=auth_headers
    )
    assert response.status_code == 400
    assert response.json()["detail"] == INCORRECT_CURRENT_PASSWORD
