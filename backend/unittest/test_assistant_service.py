import pytest
from unittest.mock import AsyncMock, MagicMock
from fastapi import HTTPException
from app.services.assistant_service import process_assistant_message, generate_daily_greeting_service

@pytest.mark.asyncio
async def test_process_assistant_message_missing_key(mocker, mock_user):
    mocker.patch("app.services.assistant_service.settings.OPENROUTER_API_KEY", "")
    mock_request = MagicMock()
    with pytest.raises(HTTPException) as exc:
        await process_assistant_message(mock_user, mock_request)
    assert exc.value.status_code == 503

@pytest.mark.asyncio
async def test_generate_daily_greeting_service_success(mocker, mock_user):
    mocker.patch("app.services.assistant_service.settings.OPENROUTER_API_KEY", "fake_key")
    
    # mock httpx post
    mock_post = mocker.patch("httpx.AsyncClient.post", new_callable=AsyncMock)
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "choices": [{"message": {"content": "Merhaba Test!"}}]
    }
    mock_post.return_value = mock_response
    
    # mock briefing fetch
    mocker.patch("app.use_cases.assistant_tools.handle_get_daily_briefing", return_value={}, new_callable=AsyncMock)
    
    result = await generate_daily_greeting_service(mock_user)
    assert result == "Merhaba Test!"
