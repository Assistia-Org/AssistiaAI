import unittest
from unittest.mock import patch, AsyncMock, MagicMock
import json
import httpx

from app.services.ai_service import (
    analyze_ticket_with_gemini,
    analyze_bus_ticket_with_gemini,
)


class MockResponse:
    """Mock class simulating httpx.Response."""

    def __init__(self, json_data: dict, status_code: int = 200, text: str = ""):
        self._json_data = json_data
        self.status_code = status_code
        self.text = text or json.dumps(json_data)

    def json(self) -> dict:
        return self._json_data


class TestAIService(unittest.IsolatedAsyncioTestCase):
    """Test suite for AI Service."""

    def setUp(self) -> None:
        """Set up dummy ticket binary content and expected responses."""
        self.dummy_file_content = b"fake binary image content"
        self.dummy_mime_type = "image/png"

        self.mock_flight_data = {
            "pnr": "TK1234",
            "airline": "Turkish Airlines",
            "flight_no": "TK2024",
            "departure": "IST",
            "arrival": "ESB",
            "date": "2026-06-01",
            "departure_time": "14:00",
            "arrival_time": "15:00",
            "status": "Confirmed",
            "passenger": "John Doe",
        }

        self.mock_bus_data = {
            "pnr": "BUS9876",
            "bus_company": "Kamil Koc",
            "trip_no": "10",
            "departure": "Istanbul",
            "arrival": "Ankara",
            "date": "2026-06-02",
            "departure_time": "22:00",
            "arrival_time": "04:00",
            "seat_number": "34",
            "status": "Confirmed",
            "passenger": "Jane Doe",
        }

    @patch("app.services.ai_service.settings")
    @patch("app.services.ai_service.httpx.AsyncClient")
    async def test_analyze_ticket_success(
        self, mock_async_client_cls: MagicMock, mock_settings: MagicMock
    ) -> None:
        """Test successful flight ticket analysis via Gemini/OpenRouter."""
        mock_settings.OPENROUTER_API_KEY = "fake_key"

        # Mock OpenRouter API response structure
        openrouter_response = {
            "choices": [
                {
                    "message": {
                        "content": json.dumps(self.mock_flight_data)
                    }
                }
            ]
        }

        mock_client = AsyncMock()
        mock_client.post.return_value = MockResponse(openrouter_response, status_code=200)
        mock_async_client_cls.return_value.__aenter__.return_value = mock_client

        result = await analyze_ticket_with_gemini(self.dummy_file_content, self.dummy_mime_type)

        self.assertEqual(result["pnr"], "TK1234")
        self.assertEqual(result["airline"], "Turkish Airlines")
        mock_client.post.assert_called_once()

    @patch("app.services.ai_service.settings")
    async def test_analyze_ticket_missing_api_key(self, mock_settings: MagicMock) -> None:
        """Test flight ticket analysis when OpenRouter API Key is missing."""
        mock_settings.OPENROUTER_API_KEY = None

        result = await analyze_ticket_with_gemini(self.dummy_file_content, self.dummy_mime_type)

        self.assertEqual(result["error"], "API Key is missing")

    @patch("app.services.ai_service.settings")
    @patch("app.services.ai_service.httpx.AsyncClient")
    async def test_analyze_ticket_api_error(
        self, mock_async_client_cls: MagicMock, mock_settings: MagicMock
    ) -> None:
        """Test flight ticket analysis handling of non-200 API responses."""
        mock_settings.OPENROUTER_API_KEY = "fake_key"

        mock_client = AsyncMock()
        mock_client.post.return_value = MockResponse({"error": "Unauthorized"}, status_code=401, text="Unauthorized access")
        mock_async_client_cls.return_value.__aenter__.return_value = mock_client

        result = await analyze_ticket_with_gemini(self.dummy_file_content, self.dummy_mime_type)

        self.assertEqual(result["error"], "API Error: 401")

    @patch("app.services.ai_service.settings")
    @patch("app.services.ai_service.httpx.AsyncClient")
    async def test_analyze_ticket_json_parse_error(
        self, mock_async_client_cls: MagicMock, mock_settings: MagicMock
    ) -> None:
        """Test flight ticket analysis handling of invalid JSON response content."""
        mock_settings.OPENROUTER_API_KEY = "fake_key"

        openrouter_response = {
            "choices": [
                {
                    "message": {
                        "content": "Not a JSON string at all"
                    }
                }
            ]
        }

        mock_client = AsyncMock()
        mock_client.post.return_value = MockResponse(openrouter_response, status_code=200)
        mock_async_client_cls.return_value.__aenter__.return_value = mock_client

        result = await analyze_ticket_with_gemini(self.dummy_file_content, self.dummy_mime_type)

        self.assertEqual(result["error"], "JSON parsing error")
        self.assertEqual(result["content"], "Not a JSON string at all")

    @patch("app.services.ai_service.settings")
    @patch("app.services.ai_service.httpx.AsyncClient")
    async def test_analyze_ticket_exception(
        self, mock_async_client_cls: MagicMock, mock_settings: MagicMock
    ) -> None:
        """Test flight ticket analysis throwing and raising general exceptions."""
        mock_settings.OPENROUTER_API_KEY = "fake_key"

        mock_client = AsyncMock()
        mock_client.post.side_effect = httpx.RequestError("Network connection failed")
        mock_async_client_cls.return_value.__aenter__.return_value = mock_client

        with self.assertRaises(httpx.RequestError):
            await analyze_ticket_with_gemini(self.dummy_file_content, self.dummy_mime_type)

    @patch("app.services.ai_service.settings")
    @patch("app.services.ai_service.httpx.AsyncClient")
    async def test_analyze_bus_ticket_success(
        self, mock_async_client_cls: MagicMock, mock_settings: MagicMock
    ) -> None:
        """Test successful bus ticket analysis via Gemini/OpenRouter."""
        mock_settings.OPENROUTER_API_KEY = "fake_key"

        # Mock OpenRouter API response structure
        openrouter_response = {
            "choices": [
                {
                    "message": {
                        "content": json.dumps(self.mock_bus_data)
                    }
                }
            ]
        }

        mock_client = AsyncMock()
        mock_client.post.return_value = MockResponse(openrouter_response, status_code=200)
        mock_async_client_cls.return_value.__aenter__.return_value = mock_client

        result = await analyze_bus_ticket_with_gemini(self.dummy_file_content, self.dummy_mime_type)

        self.assertEqual(result["pnr"], "BUS9876")
        self.assertEqual(result["bus_company"], "Kamil Koc")
        mock_client.post.assert_called_once()

    @patch("app.services.ai_service.settings")
    async def test_analyze_bus_ticket_missing_api_key(self, mock_settings: MagicMock) -> None:
        """Test bus ticket analysis when OpenRouter API Key is missing."""
        mock_settings.OPENROUTER_API_KEY = None

        result = await analyze_bus_ticket_with_gemini(self.dummy_file_content, self.dummy_mime_type)

        self.assertEqual(result["error"], "API Key is missing")

    @patch("app.services.ai_service.settings")
    @patch("app.services.ai_service.httpx.AsyncClient")
    async def test_analyze_bus_ticket_api_error(
        self, mock_async_client_cls: MagicMock, mock_settings: MagicMock
    ) -> None:
        """Test bus ticket analysis handling of non-200 API responses."""
        mock_settings.OPENROUTER_API_KEY = "fake_key"

        mock_client = AsyncMock()
        mock_client.post.return_value = MockResponse({"error": "Bad Request"}, status_code=400, text="Bad request details")
        mock_async_client_cls.return_value.__aenter__.return_value = mock_client

        result = await analyze_bus_ticket_with_gemini(self.dummy_file_content, self.dummy_mime_type)

        self.assertEqual(result["error"], "API Error: 400")

    @patch("app.services.ai_service.settings")
    @patch("app.services.ai_service.httpx.AsyncClient")
    async def test_analyze_bus_ticket_json_parse_error(
        self, mock_async_client_cls: MagicMock, mock_settings: MagicMock
    ) -> None:
        """Test bus ticket analysis handling of invalid JSON response content."""
        mock_settings.OPENROUTER_API_KEY = "fake_key"

        openrouter_response = {
            "choices": [
                {
                    "message": {
                        "content": "Not a JSON string at all"
                    }
                }
            ]
        }

        mock_client = AsyncMock()
        mock_client.post.return_value = MockResponse(openrouter_response, status_code=200)
        mock_async_client_cls.return_value.__aenter__.return_value = mock_client

        result = await analyze_bus_ticket_with_gemini(self.dummy_file_content, self.dummy_mime_type)

        self.assertEqual(result["error"], "JSON parsing error")
        self.assertEqual(result["content"], "Not a JSON string at all")

    @patch("app.services.ai_service.settings")
    @patch("app.services.ai_service.httpx.AsyncClient")
    async def test_analyze_bus_ticket_exception(
        self, mock_async_client_cls: MagicMock, mock_settings: MagicMock
    ) -> None:
        """Test bus ticket analysis throwing and raising general exceptions."""
        mock_settings.OPENROUTER_API_KEY = "fake_key"

        mock_client = AsyncMock()
        mock_client.post.side_effect = httpx.RequestError("Network connection failed")
        mock_async_client_cls.return_value.__aenter__.return_value = mock_client

        with self.assertRaises(httpx.RequestError):
            await analyze_bus_ticket_with_gemini(self.dummy_file_content, self.dummy_mime_type)


if __name__ == "__main__":
    unittest.main()
