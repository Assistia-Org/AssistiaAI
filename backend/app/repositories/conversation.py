from beanie import PydanticObjectId

from backend.app.models.conversation import Conversation, Message
from backend.app.schemas.conversation import ConversationCreate


async def create_conversation(data: ConversationCreate) -> Conversation:
    conversation = Conversation(**data.model_dump())
    return await conversation.insert()


async def get_conversation_by_id(conversation_id: str) -> Conversation | None:
    try:
        obj_id = PydanticObjectId(conversation_id)
    except Exception:
        return None

    conversation = await Conversation.get(obj_id)

    if not conversation:
        return None

    if getattr(conversation, "is_deleted", False):
        return None

    return conversation


async def get_conversations_by_user(user_id: str) -> list[Conversation]:
    try:
        obj_id = PydanticObjectId(user_id)
    except Exception:
        return []

    return await Conversation.find(
        Conversation.user_id == obj_id,
        Conversation.is_deleted == False
    ).sort(-Conversation.timestamp).to_list()


async def add_message_to_conversation(
    conversation_id: str,
    role: str,
    text: str
) -> Conversation | None:

    conversation = await get_conversation_by_id(conversation_id)

    if not conversation:
        return None

    message = Message(role=role, text=text)

    conversation.messages.append(message)

    await conversation.save()

    return conversation


async def update_conversation_intent(
    conversation_id: str,
    intent: str
) -> Conversation | None:

    conversation = await get_conversation_by_id(conversation_id)

    if not conversation:
        return None

    conversation.intent = intent

    await conversation.save()

    return conversation


async def soft_delete_conversation(conversation_id: str) -> Conversation | None:

    conversation = await get_conversation_by_id(conversation_id)

    if not conversation:
        return None

    conversation.is_deleted = True

    await conversation.save()

    return conversation