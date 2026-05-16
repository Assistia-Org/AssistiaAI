import pytest
from unittest.mock import AsyncMock, MagicMock
from fastapi import HTTPException
from app.services.notification_service import mark_as_read_service

@pytest.mark.asyncio
async def test_mark_notification_as_read_not_found(mocker, mock_user):
    mocker.patch("app.services.notification_service.get_notification_by_id", return_value=None, new_callable=AsyncMock)
    with pytest.raises(HTTPException):
        await mark_as_read_service(mock_user, "inv_id")

@pytest.mark.asyncio
async def test_mark_notification_as_read_success(mocker, mock_user):
    mock_notif = MagicMock()
    mock_notif.user_id = str(mock_user.id)
    mock_notif.is_read = False
    mock_notif.save = AsyncMock()
    
    mocker.patch("app.services.notification_service.get_notification_by_id", return_value=mock_notif, new_callable=AsyncMock)
    mocker.patch("app.services.notification_service.NotificationResponse.model_validate", return_value=MagicMock())
    
    await mark_as_read_service(mock_user, "inv_id")
