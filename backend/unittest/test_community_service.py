import pytest
from unittest.mock import AsyncMock, MagicMock
from fastapi import HTTPException
from app.services.community_service import (
    create_community_service,
    update_community_service,
    delete_community_service,
    remove_community_member_service,
    leave_community_service
)
from app.schemas.community import CommunityCreate, CommunityUpdate

@pytest.mark.asyncio
async def test_update_community_not_found(mocker, mock_user):
    mocker.patch("app.services.community_service.get_community_by_id", return_value=None, new_callable=AsyncMock)
    with pytest.raises(HTTPException) as exc:
        await update_community_service("invalid", CommunityUpdate(), mock_user)
    assert exc.value.status_code == 404

@pytest.mark.asyncio
async def test_update_community_unauthorized(mocker, mock_user):
    mock_comm = MagicMock()
    mock_comm.owner_id = "other_user"
    mocker.patch("app.services.community_service.get_community_by_id", return_value=mock_comm, new_callable=AsyncMock)
    with pytest.raises(HTTPException) as exc:
        await update_community_service("valid", CommunityUpdate(), mock_user)
    assert exc.value.status_code == 403

@pytest.mark.asyncio
async def test_remove_community_member_self(mocker, mock_user):
    mock_comm = MagicMock()
    mock_comm.owner_id = str(mock_user.id)
    mocker.patch("app.services.community_service.get_community_by_id", return_value=mock_comm, new_callable=AsyncMock)
    with pytest.raises(HTTPException) as exc:
        await remove_community_member_service("comm_id", str(mock_user.id), mock_user)
    assert exc.value.status_code == 400
    assert "Kendinizi" in exc.value.detail or "cannot" in exc.value.detail.lower()

@pytest.mark.asyncio
async def test_leave_community_as_owner(mocker, mock_user):
    mock_comm = MagicMock()
    mock_comm.owner_id = str(mock_user.id)
    mocker.patch("app.services.community_service.get_community_by_id", return_value=mock_comm, new_callable=AsyncMock)
    with pytest.raises(HTTPException) as exc:
        await leave_community_service("comm_id", mock_user)
    assert exc.value.status_code == 400
    assert "ayrılamaz" in exc.value.detail or "cannot" in exc.value.detail.lower()

@pytest.mark.asyncio
async def test_leave_community_success(mocker, mock_user):
    mock_comm = MagicMock()
    mock_comm.owner_id = "other_user"
    mocker.patch("app.services.community_service.get_community_by_id", return_value=mock_comm, new_callable=AsyncMock)
    mocker.patch("app.services.community_service.remove_community_member", return_value=True, new_callable=AsyncMock)
    mocker.patch("app.services.community_service.remove_community_role", new_callable=AsyncMock)
    
    result = await leave_community_service("comm_id", mock_user)
    assert "ayrıldı" in result.lower() or "left" in result.lower()
