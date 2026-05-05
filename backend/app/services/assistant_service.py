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
                "Kullanıcının günlük hayatındaki her türlü iş, kişisel etkinlik (spor, tenis, yemek, yürüyüş vb.), toplantı veya görevi oluşturur. "
                "Kullanıcı 'randevu' veya 'etkinlik' dese bile, eğer uçak/otel/araç kiralama gibi resmi bir biletleme değilse KESİNLİKLE bu aracı kullan. (type='Etkinlik', 'Spor', 'Görev' vs. yapabilirsin). "
                "Topluluk görevi ise önce list_my_communities çağır, topluluğu sor."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "title": {"type": "string", "description": "Görev veya toplantı başlığı."},
                    "type": {
                        "type": "string",
                        "description": "Tür. Toplantı ise 'Toplantı', standart görev ise 'Görev' yaz.",
                    },
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
                "SADECE resmi dış mekan biletlemeleri ve rezervasyonları (uçuş, otel, araç kiralama, restoran) oluşturur. "
                "DİKKAT: Spor, tenis, kişisel buluşmalar, arkadaş randevuları, ofis/iş 'toplantıları' veya günlük aktiviteler için BURAYI DEĞİL, KESİNLİKLE 'create_task' aracını kullan!"
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
                "Bir topluluk için görev veya toplantı oluşturur ve belirli üyelere atar. "
                "Kullanıcı 'takıma görev/toplantı ver' gibi ifadeler kullandığında çağır. "
                "Akış: 1) list_my_communities → topluluk seç "
                "2) get_community_members → kullanıcıya kime atanacağını sor "
                "3) bu tool'u community_id + assigned_to ile çağır."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "community_id": {"type": "string", "description": "Topluluk ID'si."},
                    "title": {"type": "string", "description": "Görev/Toplantı başlığı."},
                    "type": {"type": "string", "description": "Tür: 'Toplantı' veya 'Görev'."},
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
            "name": "get_daily_briefing",
            "description": (
                "Belirli bir günün (bugün, yarın vb.) görevlerini, rezervasyonlarını ve programını getirir. "
                "Kullanıcı 'bugün ne var', 'yarın programım ne', 'gelecek salı görevlerim' "
                "gibi sorular sorduğunda çağır. Veriyi aldıktan sonra doğal, çarpıcı bir Türkçe özet yaz."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "target_date": {"type": "string", "description": "Programı istenen günün tarihi, ISO 8601 formatında (YYYY-MM-DD). Boş bırakılırsa bugün kabul edilir."}
                }
            },
        },
    },
]

# ---------------------------------------------------------------------------
# System prompt builder
# ---------------------------------------------------------------------------


def _build_system_prompt(current_user: User, timezone_offset: str, now_local: datetime) -> str:
    """Construct the system prompt injected at the start of every LLM call."""
    days_tr = {
        "Monday": "Pazartesi",
        "Tuesday": "Salı",
        "Wednesday": "Çarşamba",
        "Thursday": "Perşembe",
        "Friday": "Cuma",
        "Saturday": "Cumartesi",
        "Sunday": "Pazar"
    }
    day_name = days_tr.get(now_local.strftime("%A"), "")
    
    upcoming_days = []
    for i in range(8):
        dt = now_local + timedelta(days=i)
        d_name = days_tr.get(dt.strftime("%A"), "")
        if i == 0:
            upcoming_days.append(f"Bugün: {dt.strftime('%Y-%m-%d')} {d_name}")
        elif i == 1:
            upcoming_days.append(f"Yarın: {dt.strftime('%Y-%m-%d')} {d_name}")
        else:
            upcoming_days.append(f"{dt.strftime('%Y-%m-%d')} {d_name}")
            
    calendar_str = "\n".join(upcoming_days)
    
    return f"""Sen AssistiaAI'nin Türkçe konuşan akıllı asistanısın. Kullanıcıların günlük programını, görevlerini ve rezervasyonlarını yönetmelerine yardımcı olursun.

Mevcut kullanıcı: {current_user.display_name} (ID: {current_user.id})
Şu anki saat: {now_local.strftime('%H:%M')} (UTC{timezone_offset})

TAKAVİM (Göreceli tarihler için bu takvimi kullan):
{calendar_str}

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
6. Kullanıcı "bugün ne var", "yarın ne var", "programım ne" gibi sorular sorarsa get_daily_briefing çağır (gerekirse target_date vererek), sonra zengin bir özet sun.
7. Kullanıcı bir görevi güncellemek/tamamlamak isteyip ID vermemişse, önce list_my_tasks çağır, doğru görevi bul.
8. Bir araç çağrısı başarılı olduğunda doğal ve kısa bir onay mesajı yaz (emojili olabilir ✓).
9. Hata durumunda nazikçe kullanıcıyı bilgilendir.
10. Hiçbir zaman hassas kullanıcı verilerini (şifre, token vb.) tekrarlama.
11. Sadece sana verilen araçlarla yapabileceğin şeyleri yap; diğer istekleri nazikçe reddet.
12. KRİTİK: Sana gönderilen konuşma geçmişinde daha önce yaptığın işlemlerin araç (tool) çağrıları gizlenmiş olabilir ve sadece verdiğin düz metin cevaplar görünebilir. Bunu görüp "demek ki araç çağırmadan sadece 'oluşturdum' diyebilirim" diye DÜŞÜNME. Yeni bir işlem (görev, toplantı vb.) istendiğinde KESİNLİKLE VE HER ZAMAN ilgili aracı (tool) çağırarak işlemi gerçekleştir.
13. KRİTİK ZİNCİRLEME: Zincirleme işlemlerde (Örn: Önce görevleri listele, ID bul, sonra güncelle) ASLA kullanıcıdan onay, izin veya cevap bekleme! "Sorgu yapıyorum", "ID'yi buldum, güncelleyeyim mi?" gibi ara raporlar VERME! Tüm adımları tek nefeste arka arkaya (otomatik loop içinde) hallet ve kullanıcıya SADECE işlem tamamen bittiğinde "Güncellendi" yaz.
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

    # Append current user message with a strong reminder
    user_msg_content = request.message
    if len(request.conversation_history) > 0:
        user_msg_content += "\n\n[Sistem Notu: Eğer yukarıdaki isteğim bir görev, toplantı veya işlem gerektiriyorsa, sadece metinle cevap verme! MUTLAKA ilgili aracı (tool) çağır. Geçmişteki yazışmalara aldanıp aracı çağırmadan 'oluşturdum' deme.]"
        
    messages.append({"role": "user", "content": user_msg_content})

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
                "model": "google/gemini-3.1-flash-lite-preview",
                "messages": messages,
                "tools": TOOLS,
                "tool_choice": "auto",
                "max_tokens": 2048,
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
