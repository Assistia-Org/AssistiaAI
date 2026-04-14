from fastapi import APIRouter, status
from backend.app.schemas.conversation import ConversationCreate, ConversationOut
from backend.app.services.conversation_service import (
    create_conversation_service,
    delete_conversation_service,
    get_conversation_service,
    list_conversations_by_user_service,
    add_message_to_conversation_service,
    update_conversation_intent_service,
)

router = APIRouter(prefix="/conversations", tags=["conversations"])


@router.post("/", response_model=ConversationOut, status_code=status.HTTP_201_CREATED)
async def create_conversation(data: ConversationCreate) -> ConversationOut:
    """
    Sohbet (conversation) oluşturma endpoint'i.
    Sisteme yeni bir sohbet başlatır.
    """
    return await create_conversation_service(data)


@router.get("/{conversation_id}", response_model=ConversationOut, status_code=status.HTTP_200_OK)
async def get_conversation(conversation_id: str) -> ConversationOut:
    """
    Sohbet getirme endpoint'i.
    Belirli bir sohbetin ID'siyle beraber mesaj geçmişini döndürür.
    """
    return await get_conversation_service(conversation_id)


@router.get("/user/{user_id}", response_model=list[ConversationOut], status_code=status.HTTP_200_OK)
async def list_user_conversations(user_id: str) -> list[ConversationOut]:
    """
    Kullanıcıya özel sohbetleri listeleme endpoint'i.
    Kullanıcının daha önce yaptığı açık ve tamamlanmış tüm sohbetlerini getirir.
    """
    return await list_conversations_by_user_service(user_id)


@router.post("/{conversation_id}/messages", response_model=ConversationOut, status_code=status.HTTP_200_OK)
async def add_message(conversation_id: str, role: str, text: str) -> ConversationOut:
    """
    Sohbete mesaj ekleme endpoint'i.
    Mevcut sohbete kullanıcı veya asistan (role) olarak yeni bir mesaj ekler.
    """
    return await add_message_to_conversation_service(conversation_id, role, text)


@router.patch("/{conversation_id}/intent", response_model=ConversationOut, status_code=status.HTTP_200_OK)
async def update_intent(conversation_id: str, intent: str) -> ConversationOut:
    """
    Sohbet intent (amaç) güncelleme endpoint'i.
    Sohbetin genel amacını etiketlemek için kullanılır.
    """
    return await update_conversation_intent_service(conversation_id, intent)


@router.delete("/{conversation_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_conversation(conversation_id: str) -> None:
    """
    Sohbet (conversation) silme endpoint'i.
    Sohbet geçmişini sistemden soft-delete olarak siler.
    """
    await delete_conversation_service(conversation_id)
