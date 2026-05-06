from fastapi import APIRouter, Depends, status

from app.api.dependencies.auth import get_current_user
from app.models.user import User
from app.schemas.assistant import AssistantChatRequest, AssistantChatResponse, DailyGreetingResponse
from app.services.assistant_service import process_assistant_message, generate_daily_greeting_service

router = APIRouter(prefix="/assistant", tags=["assistant"])


@router.post("/chat", response_model=AssistantChatResponse, status_code=status.HTTP_200_OK)
async def assistant_chat(
    data: AssistantChatRequest,
    current_user: User = Depends(get_current_user),
) -> AssistantChatResponse:
    """
    AI asistan sohbet endpoint'i.

    Kullanıcının doğal dil mesajını alır, LLM ile intent + parametre çıkarır
    ve ilgili işlemi (rezervasyon oluşturma, görev atama vb.) otomatik gerçekleştirir.
    Konuşma geçmişi Flutter tarafında tutulur; her istekte conversation_history olarak gönderilir.
    """
    return await process_assistant_message(current_user, data)


@router.get("/daily-greeting", response_model=DailyGreetingResponse, status_code=status.HTTP_200_OK)
async def get_daily_greeting(
    target_date: str | None = None,
    current_user: User = Depends(get_current_user),
) -> DailyGreetingResponse:
    """
    Get an AI-generated daily greeting based on the user's schedule.
    """
    greeting = await generate_daily_greeting_service(current_user, target_date)
    return DailyGreetingResponse(greeting=greeting)
