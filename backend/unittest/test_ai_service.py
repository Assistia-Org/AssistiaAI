import pytest
import httpx
import json
from unittest.mock import AsyncMock, MagicMock
from app.services.ai_service import analyze_ticket_with_gemini, analyze_bus_ticket_with_gemini
from app.core.config import settings

@pytest.fixture
def mock_httpx_post(mocker):
    return mocker.patch("httpx.AsyncClient.post", new_callable=AsyncMock)

@pytest.mark.asyncio
async def test_analyze_ticket_missing_api_key(mocker):
    mocker.patch("app.services.ai_service.settings.OPENROUTER_API_KEY", "")
    result = await analyze_ticket_with_gemini(b"fake_content", "image/jpeg")
    assert "error" in result
    assert result["error"] == "API Key is missing"

@pytest.mark.asyncio
async def test_analyze_ticket_success(mock_httpx_post, mocker):
    mocker.patch("app.services.ai_service.settings.OPENROUTER_API_KEY", "fake_key")
    
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "choices": [
            {
                "message": {
                    "content": '```json\n{"pnr": "123456", "airline": "Turkish Airlines"}\n```'
                }
            }
        ]
    }
    mock_httpx_post.return_value = mock_response
    
    result = await analyze_ticket_with_gemini(b"fake_content", "image/png")
    assert result["pnr"] == "123456"
    assert result["airline"] == "Turkish Airlines"

@pytest.mark.asyncio
async def test_analyze_ticket_http_error(mock_httpx_post, mocker):
    mocker.patch("app.services.ai_service.settings.OPENROUTER_API_KEY", "fake_key")
    
    mock_response = MagicMock()
    mock_response.status_code = 500
    mock_response.text = "Internal Server Error"
    mock_httpx_post.return_value = mock_response
    
    result = await analyze_ticket_with_gemini(b"fake_content", "image/jpeg")
    assert "error" in result
    assert "API Error: 500" in result["error"]

@pytest.mark.asyncio
async def test_analyze_ticket_json_error(mock_httpx_post, mocker):
    mocker.patch("app.services.ai_service.settings.OPENROUTER_API_KEY", "fake_key")
    
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "choices": [
            {
                "message": {
                    "content": 'This is not a JSON'
                }
            }
        ]
    }
    mock_httpx_post.return_value = mock_response
    
    result = await analyze_ticket_with_gemini(b"fake_content", "image/jpeg")
    assert "error" in result
    assert result["error"] == "JSON parsing error"

@pytest.mark.asyncio
async def test_analyze_bus_ticket_success(mock_httpx_post, mocker):
    mocker.patch("app.services.ai_service.settings.OPENROUTER_API_KEY", "fake_key")
    
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "choices": [
            {
                "message": {
                    "content": '{"pnr": "BUS123", "bus_company": "Kamil Koç"}'
                }
            }
        ]
    }
    mock_httpx_post.return_value = mock_response
    
    # Test mime_type fallback logic
    result = await analyze_bus_ticket_with_gemini(b"fake_content", "image")
    assert result["pnr"] == "BUS123"
    assert result["bus_company"] == "Kamil Koç"

@pytest.mark.asyncio
async def test_analyze_ticket_timeout(mock_httpx_post, mocker):
    mocker.patch("app.services.ai_service.settings.OPENROUTER_API_KEY", "fake_key")
    
    # Mocking httpx Timeout exception
    mock_httpx_post.side_effect = httpx.TimeoutException("Timeout")
    
    with pytest.raises(httpx.TimeoutException):
        await analyze_ticket_with_gemini(b"fake_content", "application/pdf")
