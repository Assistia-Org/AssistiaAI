import unittest
from unittest.mock import patch, AsyncMock, MagicMock
import json
import httpx
from fastapi import HTTPException

from app.services.assistant_service import (
    process_assistant_message,
    generate_daily_greeting_service,
)
from app.schemas.assistant import AssistantChatRequest, ConversationMessage
from app.models.user import User, PersonalSettingsModel
from app.core.messages.error_message import ASSISTANT_LLM_ERROR


class DummyUser(str):
    """A lightweight dummy class subclassing str to seamlessly pass string/link validations."""

    def __new__(cls, id: str, *args, **kwargs):
        return super().__new__(cls, id)

    def __init__(self, id: str, username: str, display_name: str, email: str):
        self.id = id
        self._id = id
        self.username = username
        self.display_name = display_name
        self.email = email
        self.personal_settings = PersonalSettingsModel()
        self.joined_communities = []


class MockResponse:
    """Mock class simulating httpx.Response."""

    def __init__(self, json_data: dict, status_code: int = 200, text: str = ""):
        self._json_data = json_data
        self.status_code = status_code
        self.text = text or json.dumps(json_data)

    def json(self) -> dict:
        return self._json_data

    def raise_for_status(self) -> None:
        if self.status_code >= 400:
            raise httpx.HTTPStatusError("HTTP Error", request=MagicMock(), response=self)


class TestAssistantService(unittest.IsolatedAsyncioTestCase):
    """Test suite for Assistant Service."""

    def setUp(self) -> None:
        """Set up standard mock user and request details."""
        self.mock_user = DummyUser("user123", "owner", "Owner User", "owner@example.com")
        self.mock_chat_request = AssistantChatRequest(
            message="Bugün ne yapmam gerekiyor?",
            timezone_offset="+03:00",
            conversation_history=[
                ConversationMessage(role="user", content="Merhaba"),
                ConversationMessage(role="assistant", content="Merhaba! Nasıl yardımcı olabilirim?"),
            ],
        )

    @patch("app.services.assistant_service.settings")
    @patch("app.services.assistant_service.httpx.AsyncClient")
    async def test_process_assistant_message_success_direct_text(
        self, mock_async_client_cls: MagicMock, mock_settings: MagicMock
    ) -> None:
        """Test successful conversation response returning direct text without tools."""
        mock_settings.OPENROUTER_API_KEY = "fake_key"

        openrouter_response = {
            "choices": [
                {
                    "finish_reason": "stop",
                    "message": {
                        "role": "assistant",
                        "content": "Bugün iki önemli toplantınız görünüyor.",
                    },
                }
            ]
        }

        mock_client = AsyncMock()
        mock_client.post.return_value = MockResponse(openrouter_response, status_code=200)
        mock_async_client_cls.return_value.__aenter__.return_value = mock_client

        response = await process_assistant_message(self.mock_user, self.mock_chat_request)

        self.assertEqual(response.reply, "Bugün iki önemli toplantınız görünüyor.")
        self.assertIsNone(response.action_performed)
        self.assertIsNone(response.result)
        self.assertFalse(response.needs_clarification)
        mock_client.post.assert_called_once()

    @patch("app.services.assistant_service.settings")
    @patch("app.services.assistant_service.dispatch_tool", new_callable=AsyncMock)
    @patch("app.services.assistant_service.httpx.AsyncClient")
    async def test_process_assistant_message_success_with_agentic_tool_loop(
        self,
        mock_async_client_cls: MagicMock,
        mock_dispatch_tool: AsyncMock,
        mock_settings: MagicMock,
    ) -> None:
        """Test agentic tool execution loop where a tool is called, executed, and fed back to LLM."""
        mock_settings.OPENROUTER_API_KEY = "fake_key"

        # 1. First LLM response: Emits a tool call
        first_llm_response = {
            "choices": [
                {
                    "finish_reason": "tool_calls",
                    "message": {
                        "role": "assistant",
                        "tool_calls": [
                            {
                                "id": "call_123",
                                "type": "function",
                                "function": {
                                    "name": "create_task",
                                    "arguments": '{"title": "Futbol Maçı"}',
                                },
                            }
                        ],
                    },
                }
            ]
        }

        # 2. Second LLM response: After feeding back the tool execution result
        second_llm_response = {
            "choices": [
                {
                    "finish_reason": "stop",
                    "message": {
                        "role": "assistant",
                        "content": "Futbol Maçı görevi başarıyla oluşturuldu! ✓",
                    },
                }
            ]
        }

        # Mock dispatch_tool execution return value
        tool_result = {"status": "success", "task_id": "task_abc"}
        mock_dispatch_tool.return_value = tool_result

        mock_client = AsyncMock()
        mock_client.post.side_effect = [
            MockResponse(first_llm_response, status_code=200),
            MockResponse(second_llm_response, status_code=200),
        ]
        mock_async_client_cls.return_value.__aenter__.return_value = mock_client

        response = await process_assistant_message(self.mock_user, self.mock_chat_request)

        self.assertEqual(response.reply, "Futbol Maçı görevi başarıyla oluşturuldu! ✓")
        self.assertEqual(response.action_performed, "create_task")
        self.assertEqual(response.result, tool_result)
        self.assertFalse(response.needs_clarification)
        self.assertEqual(mock_client.post.call_count, 2)
        mock_dispatch_tool.assert_called_once_with("create_task", {"title": "Futbol Maçı"}, self.mock_user)

    @patch("app.services.assistant_service.settings")
    @patch("app.services.assistant_service.dispatch_tool", new_callable=AsyncMock)
    @patch("app.services.assistant_service.httpx.AsyncClient")
    async def test_process_assistant_message_tool_error_handled(
        self,
        mock_async_client_cls: MagicMock,
        mock_dispatch_tool: AsyncMock,
        mock_settings: MagicMock,
    ) -> None:
        """Test that tool HTTPExceptions are gracefully caught and formatted without breaking the loop."""
        mock_settings.OPENROUTER_API_KEY = "fake_key"

        first_llm_response = {
            "choices": [
                {
                    "finish_reason": "tool_calls",
                    "message": {
                        "role": "assistant",
                        "tool_calls": [
                            {
                                "id": "call_123",
                                "type": "function",
                                "function": {
                                    "name": "create_task",
                                    "arguments": '{"title": "Hatalı Görev"}',
                                },
                            }
                        ],
                    },
                }
            ]
        }

        second_llm_response = {
            "choices": [
                {
                    "finish_reason": "stop",
                    "message": {
                        "role": "assistant",
                        "content": "Görev oluşturulamadı, lütfen tekrar deneyin.",
                    },
                }
            ]
        }

        mock_dispatch_tool.side_effect = HTTPException(status_code=400, detail="Hatalı argüman")

        mock_client = AsyncMock()
        mock_client.post.side_effect = [
            MockResponse(first_llm_response, status_code=200),
            MockResponse(second_llm_response, status_code=200),
        ]
        mock_async_client_cls.return_value.__aenter__.return_value = mock_client

        response = await process_assistant_message(self.mock_user, self.mock_chat_request)

        self.assertEqual(response.reply, "Görev oluşturulamadı, lütfen tekrar deneyin.")
        self.assertIsNone(response.action_performed)
        self.assertIsNone(response.result)

    @patch("app.services.assistant_service.settings")
    async def test_process_assistant_message_missing_key(self, mock_settings: MagicMock) -> None:
        """Test process_assistant_message raises 503 if OpenRouter API Key is missing."""
        mock_settings.OPENROUTER_API_KEY = None

        with self.assertRaises(HTTPException) as ctx:
            await process_assistant_message(self.mock_user, self.mock_chat_request)

        self.assertEqual(ctx.exception.status_code, 503)
        self.assertEqual(ctx.exception.detail, ASSISTANT_LLM_ERROR)

    @patch("app.services.assistant_service.settings")
    @patch("app.services.assistant_service.httpx.AsyncClient")
    async def test_process_assistant_message_api_error_raised(
        self, mock_async_client_cls: MagicMock, mock_settings: MagicMock
    ) -> None:
        """Test process_assistant_message raises 502 if OpenRouter responds with an error status."""
        mock_settings.OPENROUTER_API_KEY = "fake_key"

        mock_client = AsyncMock()
        mock_client.post.return_value = MockResponse({}, status_code=500)
        mock_async_client_cls.return_value.__aenter__.return_value = mock_client

        with self.assertRaises(HTTPException) as ctx:
            await process_assistant_message(self.mock_user, self.mock_chat_request)

        self.assertEqual(ctx.exception.status_code, 502)
        self.assertEqual(ctx.exception.detail, ASSISTANT_LLM_ERROR)

    @patch("app.services.assistant_service.settings")
    @patch("app.use_cases.assistant_tools.handle_get_daily_briefing", new_callable=AsyncMock)
    @patch("app.services.assistant_service.httpx.AsyncClient")
    async def test_generate_daily_greeting_success(
        self,
        mock_async_client_cls: MagicMock,
        mock_get_briefing: AsyncMock,
        mock_settings: MagicMock,
    ) -> None:
        """Test successful generation of motivational daily greeting."""
        mock_settings.OPENROUTER_API_KEY = "fake_key"

        briefing_result = {"tasks": [], "reservations": []}
        mock_get_briefing.return_value = briefing_result

        openrouter_response = {
            "choices": [
                {
                    "message": {
                        "role": "assistant",
                        "content": "Bugün zihnini dinlendirmek için mükemmel bir gün! ✨",
                    }
                }
            ]
        }

        mock_client = AsyncMock()
        mock_client.post.return_value = MockResponse(openrouter_response, status_code=200)
        mock_async_client_cls.return_value.__aenter__.return_value = mock_client

        greeting = await generate_daily_greeting_service(self.mock_user, "2026-05-18")

        self.assertEqual(greeting, "Bugün zihnini dinlendirmek için mükemmel bir gün! ✨")
        mock_get_briefing.assert_called_once_with(self.mock_user, {"target_date": "2026-05-18"})
        mock_client.post.assert_called_once()

    @patch("app.services.assistant_service.settings")
    @patch("app.use_cases.assistant_tools.handle_get_daily_briefing", new_callable=AsyncMock)
    @patch("app.services.assistant_service.httpx.AsyncClient")
    async def test_generate_daily_greeting_failure_fallback(
        self,
        mock_async_client_cls: MagicMock,
        mock_get_briefing: AsyncMock,
        mock_settings: MagicMock,
    ) -> None:
        """Test greeting fallback when OpenRouter API call fails."""
        mock_settings.OPENROUTER_API_KEY = "fake_key"

        mock_get_briefing.side_effect = Exception("DB failure")

        mock_client = AsyncMock()
        mock_client.post.side_effect = Exception("API connection timed out")
        mock_async_client_cls.return_value.__aenter__.return_value = mock_client

        greeting = await generate_daily_greeting_service(self.mock_user)

        self.assertEqual(greeting, f"Merhaba {self.mock_user.display_name}, harika bir gün geçirmen dileğiyle! ✨")


if __name__ == "__main__":
    unittest.main()
