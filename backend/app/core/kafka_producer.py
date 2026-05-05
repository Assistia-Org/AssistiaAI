"""
Async Kafka producer singleton.

Uygulama başladığında (lifespan) başlatılır, kapandığında durdurulur.
Logger modülü bu producer üzerinden Kafka'ya mesaj gönderir.
"""
import asyncio
import json
import logging
from typing import Optional

from aiokafka import AIOKafkaProducer
from aiokafka.errors import KafkaConnectionError

from app.core.config import settings

_producer: Optional[AIOKafkaProducer] = None
_lock = asyncio.Lock()

std_logger = logging.getLogger(__name__)


async def get_producer() -> Optional[AIOKafkaProducer]:
    """Mevcut producer instance'ını döndürür (None ise Kafka devre dışı)."""
    return _producer


async def start_producer() -> None:
    """
    Kafka producer'ı başlatır.
    Bağlantı kurulamazsa uygulama çökmez; loglama stdout'a fallback yapar.
    """
    global _producer

    if not settings.KAFKA_BOOTSTRAP_SERVERS:
        std_logger.warning(
            "[KafkaProducer] KAFKA_BOOTSTRAP_SERVERS tanımlı değil — "
            "Kafka devre dışı, loglar sadece stdout'a yazılacak."
        )
        return

    async with _lock:
        if _producer is not None:
            return
        try:
            producer = AIOKafkaProducer(
                bootstrap_servers=settings.KAFKA_BOOTSTRAP_SERVERS,
                value_serializer=lambda v: json.dumps(v, default=str, ensure_ascii=False).encode("utf-8"),
                # Güvenilir teslimat: en az bir broker'ın onayını bekle
                acks="all",
                # Bağlantı kesilirse otomatik yeniden bağlan
                retry_backoff_ms=500,
                request_timeout_ms=10_000,
            )
            await producer.start()
            _producer = producer
            std_logger.info(
                "[KafkaProducer] Kafka producer başarıyla başlatıldı: %s",
                settings.KAFKA_BOOTSTRAP_SERVERS,
            )
        except KafkaConnectionError as exc:
            std_logger.error(
                "[KafkaProducer] Kafka bağlantısı kurulamadı — loglar stdout'a yazılacak. Hata: %s",
                exc,
            )
        except Exception as exc:  # noqa: BLE001
            std_logger.error(
                "[KafkaProducer] Producer başlatılırken beklenmedik hata: %s",
                exc,
            )


async def stop_producer() -> None:
    """Kafka producer'ı kapatır (uygulama shutdown sırasında çağrılır)."""
    global _producer
    async with _lock:
        if _producer is not None:
            await _producer.stop()
            _producer = None
            std_logger.info("[KafkaProducer] Kafka producer durduruldu.")


async def send_log(topic: str, message: dict) -> None:
    """
    Verilen topic'e JSON mesajı gönderir.
    Producer yoksa (Kafka devre dışı veya bağlantı hatası) sessizce geçer.
    """
    producer = await get_producer()
    if producer is None:
        return
    try:
        await producer.send_and_wait(topic, message)
    except Exception as exc:  # noqa: BLE001
        std_logger.warning("[KafkaProducer] Mesaj gönderilemedi: %s", exc)
