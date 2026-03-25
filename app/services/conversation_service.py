from fastapi import HTTPException
from app.core.messages.error_message import CONVERSATION_NOT_FOUND
from app.repositories.conversation import (
    create_conversation,
    get_conversation_by_id,
    get_conversations_by_user,
    add_message_to_conversation,
    update_conversation_intent,
    soft_delete_conversation,
)
from app.schemas.conversation import ConversationCreate, ConversationUpdate, ConversationOut


async def create_conversation_service(data: ConversationCreate) -> ConversationOut:
    """Orchestrate conversation creation."""
    conversation = await create_conversation(data)
    return ConversationOut.model_validate(conversation)


async def get_conversation_service(conversation_id: str) -> ConversationOut:
    """Orchestrate conversation retrieval."""
    conversation = await get_conversation_by_id(conversation_id)
    if not conversation:
        raise HTTPException(status_code=404, detail=CONVERSATION_NOT_FOUND)
    return ConversationOut.model_validate(conversation)


async def list_conversations_by_user_service(user_id: str) -> list[ConversationOut]:
    """Orchestrate listing conversations for a user."""
    conversations = await get_conversations_by_user(user_id)
    return [ConversationOut.model_validate(c) for c in conversations]


async def add_message_to_conversation_service(conversation_id: str, role: str, text: str) -> ConversationOut:
    """Orchestrate adding a message to a conversation."""
    conversation = await add_message_to_conversation(conversation_id, role, text)
    if not conversation:
        raise HTTPException(status_code=404, detail=CONVERSATION_NOT_FOUND)
    return ConversationOut.model_validate(conversation)


async def update_conversation_intent_service(conversation_id: str, intent: str) -> ConversationOut:
    """Orchestrate conversation intent update."""
    conversation = await update_conversation_intent(conversation_id, intent)
    if not conversation:
        raise HTTPException(status_code=404, detail=CONVERSATION_NOT_FOUND)
    return ConversationOut.model_validate(conversation)


async def delete_conversation_service(conversation_id: str) -> None:
    """Orchestrate conversation soft deletion."""
    conversation = await soft_delete_conversation(conversation_id)
    if not conversation:
        raise HTTPException(status_code=404, detail=CONVERSATION_NOT_FOUND)
