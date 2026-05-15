"""
AssistiaLogger — Merkezi yapılandırılmış loglama modülü.

Kullanım:
    from app.core.logger import logger

    await logger.info(
        event_type="AUTH_LOGIN",
        msg="Kullanıcı başarıyla giriş yaptı",
        user_id="abc123",
        path="/api/v1/auth/login",
        method="POST",
        status_code=200,
        duration_ms=42,
    )

Her log çağrısı:
  1. Kafka topic'ine (KAFKA_LOGS_TOPIC) async JSON mesajı gönderir.
  2. Eş zamanlı olarak standart Python logger'a da yazar (stdout fallback).
"""

import json
import logging
import time
import asyncio
import httpx
from datetime import datetime, timezone
from enum import Enum
from typing import Any, Optional

from app.core.kafka_producer import send_log
from app.core.config import settings

# ─── Log Seviyeleri ────────────────────────────────────────────────────────────

class LogLevel(str, Enum):
    DEBUG    = "DEBUG"
    INFO     = "INFO"
    WARNING  = "WARNING"
    ERROR    = "ERROR"
    CRITICAL = "CRITICAL"

# ─── Olay Türleri ──────────────────────────────────────────────────────────────

class EventType(str, Enum):
    # Auth
    AUTH_LOGIN          = "AUTH_LOGIN"
    AUTH_LOGIN_FAIL     = "AUTH_LOGIN_FAIL"
    AUTH_REGISTER       = "AUTH_REGISTER"
    AUTH_LOGOUT         = "AUTH_LOGOUT"
    AUTH_GOOGLE         = "AUTH_GOOGLE"
    AUTH_PASSWORD_RESET = "AUTH_PASSWORD_RESET"
    AUTH_PASSWORD_CHANGE= "AUTH_PASSWORD_CHANGE"
    AUTH_TOKEN_REFRESH  = "AUTH_TOKEN_REFRESH"

    # Kullanıcı
    USER_UPDATE         = "USER_UPDATE"
    USER_DELETE         = "USER_DELETE"
    USER_FCM_UPDATE     = "USER_FCM_UPDATE"

    # Görevler
    TASK_CREATE         = "TASK_CREATE"
    TASK_UPDATE         = "TASK_UPDATE"
    TASK_DELETE         = "TASK_DELETE"

    # Rezervasyonlar
    RESERVATION_CREATE  = "RESERVATION_CREATE"
    RESERVATION_UPDATE  = "RESERVATION_UPDATE"
    RESERVATION_DELETE  = "RESERVATION_DELETE"

    # Topluluk
    COMMUNITY_CREATE    = "COMMUNITY_CREATE"
    COMMUNITY_UPDATE    = "COMMUNITY_UPDATE"
    COMMUNITY_DELETE    = "COMMUNITY_DELETE"
    COMMUNITY_JOIN      = "COMMUNITY_JOIN"
    COMMUNITY_LEAVE     = "COMMUNITY_LEAVE"

    # Bildirim
    NOTIFICATION_SEND   = "NOTIFICATION_SEND"

    # API
    API_REQUEST         = "API_REQUEST"
    API_ERROR           = "API_ERROR"

    # Sistem
    SYSTEM_STARTUP      = "SYSTEM_STARTUP"
    SYSTEM_SHUTDOWN     = "SYSTEM_SHUTDOWN"

# ─── Standart Python logger (stdout fallback) ──────────────────────────────────

_std_logger = logging.getLogger("assistia")
_std_logger.setLevel(getattr(logging, settings.LOG_LEVEL, logging.INFO))

if not _std_logger.handlers:
    _handler = logging.StreamHandler()
    _handler.setFormatter(
        logging.Formatter(
            fmt="%(asctime)s | %(levelname)-8s | %(message)s",
            datefmt="%Y-%m-%dT%H:%M:%S",
        )
    )
    _std_logger.addHandler(_handler)
    _std_logger.propagate = False

# ─── AssistiaLogger ────────────────────────────────────────────────────────────

class AssistiaLogger:
    """
    Yapılandırılmış JSON loglama sınıfı.
    Tüm servisler bu singleton üzerinden `await logger.<level>(...)` çağırır.
    """

    def __init__(self, topic: str, service: str = "assistia-backend") -> None:
        self._topic   = topic
        self._service = service

    def _build_record(
        self,
        level: LogLevel,
        event_type: str,
        msg: str,
        *,
        user_id: str = "",
        username: str = "",
        email: str = "",
        path: str = "",
        method: str = "",
        status_code: int = 0,
        duration_ms: int = 0,
        ip_address: str = "",
        extra: Optional[dict] = None,
    ) -> dict[str, Any]:
        return {
            "timestamp":   datetime.now(timezone.utc).isoformat(timespec="milliseconds"),
            "level":       level.value,
            "event_type":  event_type,
            "service":     self._service,
            "method":      method,
            "path":        path,
            "status_code": status_code,
            "duration_ms": duration_ms,
            "user_id":     user_id,
            "username":    username,
            "email":       email,
            "ip_address":  ip_address,
            "msg":         msg,
            "extra":       extra or {},
        }

    async def _emit(self, record: dict) -> None:
        """Kafka'ya gönder; standart logger'a da yaz."""
        level_name = record["level"]
        log_fn = getattr(_std_logger, level_name.lower(), _std_logger.info)
        log_fn(
            "[%s] %s | user=%s(%s) path=%s status=%s dur=%sms | %s",
            record["event_type"],
            level_name,
            record.get("username") or record.get("user_id") or "-",
            record.get("email") or "-",
            record.get("path") or "-",
            record.get("status_code") or "-",
            record.get("duration_ms") or "-",
            record["msg"],
        )
        await send_log(self._topic, record)

        if level_name in (LogLevel.ERROR.value, LogLevel.CRITICAL.value) and settings.SLACK_WEBHOOK_URL:
            # Asenkron çalışması için task olarak fırlatıyoruz, ana akışı bloklamasın.
            asyncio.create_task(self._send_to_slack(record))

    async def _send_to_slack(self, record: dict) -> None:
        webhook_url = settings.SLACK_WEBHOOK_URL
        if not webhook_url:
            return

        message = (
            f"*{record['level']} - {record['event_type']}*\n"
            f"*Path:* `{record.get('path') or '-'}`\n"
            f"*User:* {record.get('username') or record.get('user_id') or '-'}\n"
            f"*Message:* {record['msg']}\n"
        )
        
        extra_data = record.get('extra', {})
        if extra_data:
            message += f"*Extra:*\n```{json.dumps(extra_data, indent=2)}```"

        payload = {"text": message}

        try:
            async with httpx.AsyncClient() as client:
                await client.post(webhook_url, json=payload, timeout=5.0)
        except Exception as e:
            # Sadece stdout'a bas ki döngüye girmesin
            _std_logger.error("Slack'e log gönderilirken hata oluştu: %s", str(e))

    # ── Seviye metodları ──────────────────────────────────────────────────────

    async def debug(self, event_type: str, msg: str, **kwargs) -> None:
        await self._emit(self._build_record(LogLevel.DEBUG, event_type, msg, **kwargs))

    async def info(self, event_type: str, msg: str, **kwargs) -> None:
        await self._emit(self._build_record(LogLevel.INFO, event_type, msg, **kwargs))

    async def warning(self, event_type: str, msg: str, **kwargs) -> None:
        await self._emit(self._build_record(LogLevel.WARNING, event_type, msg, **kwargs))

    async def error(self, event_type: str, msg: str, **kwargs) -> None:
        await self._emit(self._build_record(LogLevel.ERROR, event_type, msg, **kwargs))

    async def critical(self, event_type: str, msg: str, **kwargs) -> None:
        await self._emit(self._build_record(LogLevel.CRITICAL, event_type, msg, **kwargs))


# ── Uygulama genelinde tek instance ──────────────────────────────────────────
logger = AssistiaLogger(
    topic=settings.KAFKA_LOGS_TOPIC,
    service="assistia-backend",
)
