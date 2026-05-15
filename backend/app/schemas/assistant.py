from typing import Any, Dict, List, Literal, Optional

from pydantic import BaseModel


class ConversationMessage(BaseModel):
    """Represents a single turn in the conversation history."""

    role: Literal["user", "assistant"]
    content: str


class AssistantChatRequest(BaseModel):
    """
    Request body for the AI assistant chat endpoint.

    - message: The latest user message.
    - conversation_history: Previous turns (Flutter keeps this state).
    - timezone_offset: IANA-style offset string, e.g. '+03:00'. Used to
      resolve relative dates like 'yarın' or 'gelecek Pazartesi'.
    """

    message: str
    conversation_history: List[ConversationMessage] = []
    timezone_offset: str = "+03:00"


class AssistantChatResponse(BaseModel):
    """
    Response body returned by the AI assistant chat endpoint.

    - reply: Natural-language answer produced by the LLM.
    - action_performed: Name of the tool the LLM invoked, if any.
    - result: Structured payload returned by the invoked tool.
    - needs_clarification: True when the LLM asked the user a follow-up
      question (e.g. "Which community?") instead of executing a tool.
    """

    reply: str
    action_performed: Optional[str] = None
    result: Optional[Dict[str, Any]] = None
    needs_clarification: bool = False


class DailyGreetingResponse(BaseModel):
    """
    Response body returned by the AI daily greeting endpoint.
    
    - greeting: The AI generated daily greeting string.
    """
    
    greeting: str
