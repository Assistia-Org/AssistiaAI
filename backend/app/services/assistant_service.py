"""
AI Assistant Service.

Orchestrates the full agentic loop:
  1. Build a system prompt with current datetime + user context.
  2. Call OpenRouter with tool definitions (function calling).
  3. If the LLM emits a tool_call → dispatch it via use_cases/assistant_tools.
  4. Feed the tool result back to the LLM to produce a natural-language reply.
  5. If the LLM's reply is a follow-up question (needs_clarification) → return
     it directly without executing any action.

The loop handles at most MAX_TOOL_ROUNDS agentic steps to prevent runaway
API usage while still supporting multi-step flows like:
  user: "takıma görev oluştur"
  assistant → list_my_communities → "hangi topluluğu kastettiniz?" (clarify)
  user: "Yazılım Takımı"
  assistant → create_task(community_id=...) → "Görev oluşturuldu ✓"
"""

import json
import logging
from datetime import datetime, timezone, timedelta
from typing import Any, Dict, List, Optional

import httpx
from fastapi import HTTPException

from app.core.config import settings
from app.core.messages.error_message import ASSISTANT_LLM_ERROR
from app.models.user import User
from app.schemas.assistant import AssistantChatRequest, AssistantChatResponse, ConversationMessage
from app.use_cases.assistant_tools import dispatch_tool

logger = logging.getLogger(__name__)

# Maximum agentic rounds per single user turn to avoid runaway loops.
MAX_TOOL_ROUNDS = 5

# ---------------------------------------------------------------------------
# Tool definitions (JSON Schema — OpenAI function-calling format)
# ---------------------------------------------------------------------------

TOOLS: List[Dict[str, Any]] = [
    {
        "type": "function",
        "function": {
            "name": "create_task",
            "description": (
                "Yeni bir görev oluşturur. Kullanıcı bir iş, görev ya da yapılacak şey "
                "belirttiğinde bu aracı kullan. Topluluk görevi ise önce list_my_communities "
                "çağır, topluluğu kullanıcıya sor, ardından community_id ile tekrar çağır."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "title": {"type": "string", "description": "Görevin başlığı."},
                    "description": {"type": "string", "description": "Opsiyonel açıklama."},
                    "due_date": {
                        "type": "string",
                        "description": "Son tarih, ISO 8601 formatında (YYYY-MM-DDTHH:MM:SS). Göreceli ifadeleri (yarın, gelecek Pazartesi) mevcut tarihe göre hesapla.",
                    },
                    "start_date": {"type": "string", "description": "Başlangıç tarihi, ISO 8601."},
                    "end_date": {"type": "string", "description": "Bitiş tarihi, ISO 8601."},
                    "priority": {
                        "type": "string",
                        "enum": ["low", "medium", "high"],
                        "description": "Öncelik düzeyi.",
                    },
                    "community_id": {
                        "type": "string",
                        "description": "Topluluk ID'si. Boş bırakılırsa kişisel görev olur.",
                    },
                    "assigned_to": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "Atanacak kullanıcı ID'leri listesi.",
                    },
                },
                "required": ["title"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "update_task",
            "description": (
                "Mevcut bir görevi günceller. Kullanıcı tarih değiştirmek, öncelik "
                "ayarlamak veya başlık düzenlemek istediğinde kullan."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "task_id": {"type": "string", "description": "Güncellenecek görevin ID'si."},
                    "title": {"type": "string"},
                    "description": {"type": "string"},
                    "due_date": {"type": "string", "description": "ISO 8601."},
                    "start_date": {"type": "string", "description": "ISO 8601."},
                    "end_date": {"type": "string", "description": "ISO 8601."},
                    "priority": {"type": "string", "enum": ["low", "medium", "high"]},
                    "status": {
                        "type": "string",
                        "enum": ["pending", "in_progress", "completed", "overdue"],
                    },
                    "assigned_to": {
                        "type": "array",
                        "items": {"type": "string"},
                    },
                    "tags": {"type": "array", "items": {"type": "string"}},
                },
                "required": ["task_id"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "complete_task",
            "description": (
                "Bir görevi tamamlandı olarak işaretler. "
                "Kullanıcı 'görevi tamamla', 'bitti', 'done' gibi ifadeler kullandığında çağır."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "task_id": {"type": "string", "description": "Tamamlanacak görevin ID'si."},
                },
                "required": ["task_id"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "create_reservation",
            "description": (
                "Yeni bir rezervasyon oluşturur. Toplantı salonu, uçuş, otel, araç kiralama "
                "veya herhangi bir etkinlik rezervasyonu için kullan. Topluluk rezervasyonu "
                "ise önce list_my_communities çağır, topluluğu sor."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "category": {
                        "type": "string",
                        "enum": ["flight", "hotel", "car_rental", "meeting", "other"],
                        "description": "Rezervasyon kategorisi.",
                    },
                    "title": {"type": "string", "description": "Rezervasyon başlığı."},
                    "details": {
                        "type": "object",
                        "description": "Kategoriye özel detaylar. Örn: {room: 'A101', location: 'İstanbul'} veya {airline: 'THY', flight_no: 'TK123'}.",
                    },
                    "start_date": {"type": "string", "description": "Başlangıç tarihi/saati, ISO 8601."},
                    "end_date": {"type": "string", "description": "Bitiş tarihi/saati, ISO 8601."},
                    "community_id": {
                        "type": "string",
                        "description": "Topluluk ID'si. Boş bırakılırsa kişisel rezervasyon.",
                    },
                    "assigned_to": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "Rezervasyona atanacak kullanıcı ID'leri.",
                    },
                    "is_shared": {
                        "type": "boolean",
                        "description": "Toplulukla paylaşılsın mı?",
                    },
                    "status": {
                        "type": "string",
                        "description": "Rezervasyon durumu (confirmed, pending, cancelled).",
                    },
                },
                "required": ["category", "title"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "update_reservation",
            "description": "Mevcut bir rezervasyonu günceller.",
            "parameters": {
                "type": "object",
                "properties": {
                    "reservation_id": {"type": "string", "description": "Güncellenecek rezervasyonun ID'si."},
                    "title": {"type": "string"},
                    "details": {"type": "object"},
                    "start_date": {"type": "string", "description": "ISO 8601."},
                    "end_date": {"type": "string", "description": "ISO 8601."},
                    "status": {"type": "string"},
                    "assigned_to": {"type": "array", "items": {"type": "string"}},
                    "is_shared": {"type": "boolean"},
                },
                "required": ["reservation_id"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "list_my_tasks",
            "description": "Kullanıcının mevcut görevlerini listeler. Görevleri sormak veya bir görevin ID'sini bulmak için kullan.",
            "parameters": {"type": "object", "properties": {}},
        },
    },
    {
        "type": "function",
        "function": {
            "name": "list_my_reservations",
            "description": "Kullanıcının mevcut rezervasyonlarını listeler.",
            "parameters": {"type": "object", "properties": {}},
        },
    },
    {
        "type": "function",
        "function": {
            "name": "list_my_communities",
            "description": (
                "Kullanıcının üye olduğu toplulukları listeler. "
                "Topluluk ataması gereken işlemler öncesinde community_id öğrenmek için çağır, "
                "ardından kullanıcıya hangi topluluğu kastettiğini sor."
            ),
            "parameters": {"type": "object", "properties": {}},
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_community_members",
            "description": (
                "Belirli bir topluluktaın üye listesini getirir (isim + ID). "
                "assign_task_to_community öncesinde kime atanacağını kullanıcıya sormak için kullan. "
                "Tüm topluğa atanacaksa çağırmaya gerek yok."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "community_id": {"type": "string", "description": "Topluluk ID'si."},
                },
                "required": ["community_id"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "assign_task_to_community",
            "description": (
                "Bir topluluk için görev oluşturur ve belirli üyelere atar. "
                "Kullanıcı 'takıma görev ver', 'topluluğa at' gibi ifadeler kullandığında çağır. "
                "Aksiş: 1) list_my_communities → topluluk seç "
                "2) get_community_members → kullanıcıya kime atanacağını sor "
                "3) bu tool'u community_id + assigned_to ile çağır."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "community_id": {"type": "string", "description": "Topluluk ID'si."},
                    "title": {"type": "string", "description": "Görev başlığı."},
                    "description": {"type": "string", "description": "Opsiyonel açıklama."},
                    "due_date": {"type": "string", "description": "Son tarih, ISO 8601."},
                    "start_date": {"type": "string", "description": "Başlangıç tarihi, ISO 8601."},
                    "end_date": {"type": "string", "description": "Bitiş tarihi, ISO 8601."},
                    "priority": {"type": "string", "enum": ["low", "medium", "high"]},
                    "assigned_to": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "Atanacak üye ID'leri. Boş bırakılırsa tüm topluluğa atanr.",
                    },
                    "tags": {"type": "array", "items": {"type": "string"}},
                },
                "required": ["community_id", "title"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_today_briefing",
            "description": (
                "Bugünün görevlerini, rezervasyonlarını ve programını getirir. "
                "Kullanıcı 'bugün ne var', 'günüm nasıl', 'programım ne', 'bugünkü görevlerim' "
                "gibi sorular sorduğunda çağır. Veriyi aldıktan sonra doğal, çarpıcı bir Türkçe özet yaz."
            ),
            "parameters": {"type": "object", "properties": {}},
        },
    },
]

# ---------------------------------------------------------------------------
# System prompt builder
# ---------------------------------------------------------------------------


def _build_system_prompt(current_user: User, timezone_offset: str, now_local: datetime) -> str:
    """Construct the system prompt injected at the start of every LLM call."""
    return f"""Sen AssistiaAI'nin Türkçe konuşan akıllı asistanısın. Kullanıcıların günlük programını, görevlerini ve rezervasyonlarını yönetmelerine yardımcı olursun.

Mevcut kullanıcı: {current_user.display_name} (ID: {current_user.id})
Şu anki tarih/saat: {now_local.strftime('%Y-%m-%d %H:%M')} (UTC{timezone_offset})
Bugün: {now_local.strftime('%A, %d %B %Y')} (Türkçe günler: Pazartesi, Salı, Çarşamba, Perşembe, Cuma, Cumartesi, Pazar)

GÖREV VE DAVRANIŞ KURALLARI:
1. Her zaman Türkçe yanıt ver.
2. Göreceli tarif ("yarın", "gelecek Pazartesi", "3 saat sonra") ifadelerini yukarıdaki mevcut zamana göre ISO 8601 formatına çevir.
3. Kullanıcı KİŞİSEL görev/rezervasyon oluşturmak istiyorsa: community_id olmadan ilgili tool'u doğrudan çağır.
4. Kullanıcı TOPLULUK görevi/rezervasyonu oluşturmak istiyorsa:
   a) Önce list_my_communities çağır.
   b) Kullanıcıya hangi topluluğu kastettiğini sor (liste göster).
   c) Kullanıcı topluluğu belirtince community_id ile devam et.
5. Kullanıcı BELİRLİ ÜYELERE görev atamak istiyorsa:
   a) list_my_communities → topluluk seç
   b) get_community_members(community_id) → üye listesini göster, kime atanacağını sor
   c) assign_task_to_community(community_id, assigned_to=[...]) ile görevi oluştur.
   d) Kullanıcı tüm topluluğa atanmasını istiyorsa assigned_to boş bırak.
6. Kullanıcı "bugün ne var", "günüm nasıl", "programım ne", "bugünkü görevlerim/rezervasyonlarım" gibi sorular sorarsa get_today_briefing çağır, sonra zengin bir günlük özet sun.
7. Kullanıcı bir görevi güncellemek/tamamlamak isteyip ID vermemişse, önce list_my_tasks çağır, doğru görevi bul.
8. Bir araç çağrısı başarılı olduğunda doğal ve kısa bir onay mesajı yaz (emojili olabilir ✓).
9. Hata durumunda nazikçe kullanıcıyı bilgilendir.
10. Hiçbir zaman hassas kullanıcı verilerini (şifre, token vb.) tekrarlama.
11. Sadece sana verilen araçlarla yapabileceğin şeyleri yap; diğer istekleri nazikçe reddet.
"""


# ---------------------------------------------------------------------------
# Main service function
# ---------------------------------------------------------------------------


async def process_assistant_message(
    current_user: User,
    request: AssistantChatRequest,
) -> AssistantChatResponse:
    """
    Process one user turn through the agentic LLM loop.

    Steps:
      1. Resolve local time from timezone_offset.
      2. Build message history (system + history + current user message).
      3. Call OpenRouter with tool definitions.
      4. If tool_calls → dispatch → feed result back (loop up to MAX_TOOL_ROUNDS).
      5. Return final natural-language reply with optional structured result.
    """
    if not settings.OPENROUTER_API_KEY:
        raise HTTPException(status_code=503, detail=ASSISTANT_LLM_ERROR)

    # 1. Resolve local now from offset string (e.g. "+03:00")
    timezone_offset = request.timezone_offset
    try:
        sign = 1 if timezone_offset[0] != "-" else -1
        parts = timezone_offset.lstrip("+-").split(":")
        offset_hours = int(parts[0])
        offset_minutes = int(parts[1]) if len(parts) > 1 else 0
        tz = timezone(timedelta(hours=sign * offset_hours, minutes=sign * offset_minutes))
    except Exception:
        tz = timezone(timedelta(hours=3))  # fallback to UTC+3 (Turkey)

    now_local = datetime.now(tz)

    # 2. Build OpenRouter messages list
    system_prompt = _build_system_prompt(current_user, timezone_offset, now_local)
    messages: List[Dict[str, Any]] = [{"role": "system", "content": system_prompt}]

    # Append conversation history
    for turn in request.conversation_history:
        messages.append({"role": turn.role, "content": turn.content})

    # Append current user message
    messages.append({"role": "user", "content": request.message})

    headers = {
        "Authorization": f"Bearer {settings.OPENROUTER_API_KEY}",
        "HTTP-Referer": "https://assistia.ai",
        "X-Title": "AssistiaAI",
        "Content-Type": "application/json",
    }

    last_tool_name: Optional[str] = None
    last_tool_result: Optional[Dict[str, Any]] = None
    tool_error: bool = False  # tracks whether the last dispatched tool raised an error

    # 3. Agentic loop
    async with httpx.AsyncClient(timeout=60.0) as client:
        for round_idx in range(MAX_TOOL_ROUNDS):
            payload: Dict[str, Any] = {
                "model": "google/gemini-2.0-flash-001",
                "messages": messages,
                "tools": TOOLS,
                "tool_choice": "auto",
            }

            response = await client.post(
                "https://openrouter.ai/api/v1/chat/completions",
                headers=headers,
                json=payload,
            )

            if response.status_code != 200:
                logger.error("OpenRouter error %s: %s", response.status_code, response.text)
                raise HTTPException(status_code=502, detail=ASSISTANT_LLM_ERROR)

            llm_response = response.json()
            choice = llm_response["choices"][0]
            message_obj = choice["message"]
            finish_reason = choice.get("finish_reason", "stop")

            # 4a. LLM wants to call a tool
            if finish_reason == "tool_calls" or message_obj.get("tool_calls"):
                tool_calls = message_obj.get("tool_calls", [])
                if not tool_calls:
                    break

                # Append the assistant's tool_calls turn to history
                messages.append(message_obj)

                # Process tool calls sequentially (usually just one per round)
                for tc in tool_calls:
                    tool_name: str = tc["function"]["name"]
                    try:
                        raw_args = tc["function"].get("arguments", "{}")
                        args: Dict[str, Any] = json.loads(raw_args) if isinstance(raw_args, str) else raw_args
                    except json.JSONDecodeError:
                        args = {}

                    logger.info("Dispatching tool: %s with args: %s", tool_name, args)

                    try:
                        tool_result = await dispatch_tool(tool_name, args, current_user)
                        last_tool_name = tool_name
                        last_tool_result = tool_result
                        tool_result_content = json.dumps(tool_result, ensure_ascii=False, default=str)
                        tool_error = False
                    except HTTPException as exc:
                        tool_result_content = json.dumps({"error": exc.detail})
                        tool_error = True
                        logger.warning("Tool %s raised HTTPException: %s", tool_name, exc.detail)

                    # Append tool result to message history for next LLM call
                    messages.append({
                        "role": "tool",
                        "tool_call_id": tc.get("id", tool_name),
                        "name": tool_name,
                        "content": tool_result_content,
                    })

                # Continue the loop — LLM will now produce its natural-language reply
                continue

            # 4b. LLM produced a final text reply
            reply_content: str = message_obj.get("content") or ""

            # needs_clarification: True when the LLM is asking a follow-up question
            # rather than having completed an action.
            needs_clarification = (
                last_tool_name is None
                and (
                    "?" in reply_content
                    or "hangi" in reply_content.lower()
                    or "lütfen belirt" in reply_content.lower()
                )
            )

            return AssistantChatResponse(
                reply=reply_content.strip(),
                action_performed=last_tool_name if not tool_error else None,
                result=last_tool_result if not tool_error else None,
                needs_clarification=needs_clarification,
            )

    # Fallback if loop exhausted without a final text reply
    return AssistantChatResponse(
        reply="İşleminizi tamamlarken bir sorun oluştu. Lütfen tekrar deneyin.",
        action_performed=last_tool_name,
        result=last_tool_result,
        needs_clarification=False,
    )
