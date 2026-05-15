import logging
from typing import Any, Optional

import firebase_admin
from firebase_admin import credentials, messaging

from app.core.config import settings

logger = logging.getLogger(__name__)

_firebase_initialized = False


def init_firebase() -> None:
    """
    Initialize Firebase Admin SDK using the service account credentials file.
    Safe to call multiple times — skips if already initialized.
    """
    global _firebase_initialized
    if _firebase_initialized:
        return

    if not settings.FIREBASE_CREDENTIALS_PATH:
        logger.warning("FIREBASE_CREDENTIALS_PATH is not set. FCM push notifications are disabled.")
        return

    try:
        cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        firebase_admin.initialize_app(cred)
        _firebase_initialized = True
        logger.info("Firebase Admin SDK initialized successfully.")
    except Exception as exc:
        logger.error("Failed to initialize Firebase Admin SDK: %s", exc)


async def send_push_notification(
    fcm_token: str,
    title: str,
    body: str,
    data: Optional[dict[str, Any]] = None,
) -> bool:
    """
    Send a single FCM push notification to a device token.

    Returns True on success, False if token is missing or send fails.
    Does NOT raise — push failures should never break the main flow.
    """
    if not _firebase_initialized:
        logger.debug("Firebase not initialized. Skipping push for token: %s", fcm_token[:10])
        return False

    if not fcm_token:
        return False

    # FCM data payload values must all be strings
    str_data = {k: str(v) for k, v in (data or {}).items()}

    message = messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        data=str_data,
        token=fcm_token,
        android=messaging.AndroidConfig(priority="high"),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(sound="default", badge=1)
            )
        ),
    )

    try:
        response = messaging.send(message)
        logger.debug("FCM message sent: %s", response)
        return True
    except messaging.UnregisteredError:
        logger.warning("FCM token is no longer valid: %s", fcm_token[:10])
        return False
    except Exception as exc:
        logger.error("FCM send failed: %s", exc)
        return False
