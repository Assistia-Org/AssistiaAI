import pytest
import httpx
from app.models.user import User as UserModel

pytestmark = pytest.mark.asyncio

async def test_get_me(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test retrieving profile of current authenticated user."""
    response = await async_client.get("/api/v1/users/me", headers=auth_headers)
    assert response.status_code == 200
    json_data = response.json()
    assert json_data["email"] == "integrationtest@example.com"
    assert json_data["username"] == "integrationtestuser"

async def test_update_me(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test updating profile fields of current authenticated user."""
    update_data = {
        "display_name": "New Integration Name",
        "username": "updatedintegrationuser"
    }
    response = await async_client.post("/api/v1/users/me", json=update_data, headers=auth_headers)
    assert response.status_code == 200
    json_data = response.json()
    assert json_data["display_name"] == "New Integration Name"
    assert json_data["username"] == "updatedintegrationuser"

async def test_get_user_by_id(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test retrieving user details using their ID."""
    db_user = await UserModel.find_one(UserModel.email == "integrationtest@example.com")
    assert db_user is not None

    response = await async_client.get(f"/api/v1/users/{db_user.id}", headers=auth_headers)
    assert response.status_code == 200
    assert response.json()["email"] == "integrationtest@example.com"

async def test_get_user_by_email(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test retrieving user details using their email address."""
    response = await async_client.get(
        "/api/v1/users/email/integrationtest@example.com",
        headers=auth_headers
    )
    assert response.status_code == 200
    assert response.json()["username"] == "integrationtestuser"

async def test_list_users(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test listing all users registered in the system."""
    response = await async_client.get("/api/v1/users/", headers=auth_headers)
    assert response.status_code == 200
    assert len(response.json()) >= 1

async def test_update_user(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test updating specific user details as admin or authenticated owner."""
    db_user = await UserModel.find_one(UserModel.email == "integrationtest@example.com")
    assert db_user is not None

    update_data = {
        "display_name": "Fully Updated Name"
    }
    response = await async_client.patch(
        f"/api/v1/users/{db_user.id}",
        json=update_data,
        headers=auth_headers
    )
    assert response.status_code == 200
    assert response.json()["display_name"] == "Fully Updated Name"

async def test_delete_user(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test deleting user profile."""
    # 1. Create a dummy user
    dummy_data = {
        "username": "dummydelete",
        "display_name": "Dummy Delete",
        "email": "dummydelete@example.com",
        "password": "Password123"
    }
    register_res = await async_client.post("/api/v1/auth/register", json=dummy_data)
    assert register_res.status_code == 201

    db_user = await UserModel.find_one(UserModel.email == "dummydelete@example.com")
    assert db_user is not None

    # 2. Delete user
    delete_res = await async_client.delete(
        f"/api/v1/users/{db_user.id}",
        headers=auth_headers
    )
    assert delete_res.status_code == 204

    # 3. Verify user is deleted
    db_user_deleted = await UserModel.find_one(UserModel.email == "dummydelete@example.com")
    assert db_user_deleted is None

async def test_update_fcm_token(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test updating and storing Firebase Cloud Messaging token for authenticated user."""
    fcm_data = {"fcm_token": "fcm_test_token_12345"}
    response = await async_client.patch(
        "/api/v1/users/me/fcm-token",
        json=fcm_data,
        headers=auth_headers
    )
    assert response.status_code == 200
    assert response.json()["message"] == "FCM token updated successfully."

    db_user = await UserModel.find_one(UserModel.email == "integrationtest@example.com")
    assert db_user.fcm_token == "fcm_test_token_12345"
