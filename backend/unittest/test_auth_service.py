import pytest
from unittest.mock import AsyncMock, MagicMock
from fastapi import HTTPException
from app.services.auth_service import login_service, register_user_service
from app.schemas.user import UserCreate
from app.schemas.auth import LoginSchema

@pytest.mark.asyncio
async def test_login_service_not_found(mocker):
    mocker.patch("app.services.auth_service.get_user_by_email", return_value=None, new_callable=AsyncMock)
    with pytest.raises(HTTPException) as exc:
        await login_service(LoginSchema(email="notfound@test.com", password="pass"))
    assert exc.value.status_code == 401

@pytest.mark.asyncio
async def test_login_service_wrong_password(mocker):
    mock_user = MagicMock()
    mock_user.hashed_password = "hashed"
    mocker.patch("app.services.auth_service.get_user_by_email", return_value=mock_user, new_callable=AsyncMock)
    mocker.patch("app.services.auth_service.verify_password", return_value=False)
    with pytest.raises(HTTPException) as exc:
        await login_service(LoginSchema(email="user@test.com", password="wrongpass"))
    assert exc.value.status_code == 401

@pytest.mark.asyncio
async def test_login_service_success(mocker):
    mock_user = MagicMock()
    mock_user.id = "123"
    mock_user.username = "testuser"
    mock_user.email = "user@test.com"
    mock_user.hashed_password = "hashed"
    mocker.patch("app.services.auth_service.get_user_by_email", return_value=mock_user, new_callable=AsyncMock)
    mocker.patch("app.services.auth_service.verify_password", return_value=True)
    mocker.patch("app.services.auth_service.create_access_token", return_value="access_token")
    mocker.patch("app.services.auth_service.create_refresh_token", return_value="refresh_token")
    mocker.patch("app.services.auth_service._cache_user", new_callable=AsyncMock)
    
    result = await login_service(LoginSchema(email="user@test.com", password="StrongPassword123!"))
    assert result.access_token == "access_token"

@pytest.mark.asyncio
async def test_register_service_email_exists(mocker):
    mocker.patch("app.services.auth_service.get_user_by_email", return_value=MagicMock(), new_callable=AsyncMock)
    mocker.patch("app.services.auth_service.validate_password_strength", return_value=None)
    user_data = UserCreate(email="test@test.com", password="StrongPassword123!", username="user", display_name="Test")
    with pytest.raises(HTTPException) as exc:
        await register_user_service(user_data)
    assert exc.value.status_code == 400

@pytest.mark.asyncio
async def test_register_service_success(mocker):
    mocker.patch("app.services.auth_service.get_user_by_email", return_value=None, new_callable=AsyncMock)
    mocker.patch("app.services.auth_service.validate_password_strength", return_value=None)
    mocker.patch("app.services.auth_service.get_password_hash", return_value="hashed")
    mocker.patch("app.services.auth_service.create_user", return_value=MagicMock(), new_callable=AsyncMock)
    mocker.patch("app.services.auth_service._cache_user", new_callable=AsyncMock)
    
    mock_resp = MagicMock()
    mock_resp.email = "test@test.com"
    mocker.patch("app.services.auth_service.UserResponse.model_validate", return_value=mock_resp)
    
    user_data = UserCreate(email="test@test.com", password="StrongPassword123!", username="user", display_name="Test")
    result = await register_user_service(user_data)
    assert result.email == "test@test.com"
