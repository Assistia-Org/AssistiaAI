import json
import logging
from typing import Any, Optional

import firebase_admin
from firebase_admin import credentials, messaging

from app.core.config import settings

logger = logging.getLogger(__name__)

_firebase_initialized = False


def init_firebase() -> None:
    """
    Initialize Firebase Admin SDK using service account credentials.
    Supports either a JSON string (FIREBASE_CREDENTIALS) or a file path (FIREBASE_CREDENTIALS_PATH).
    Safe to call multiple times — skips if already initialized.
    """
    global _firebase_initialized
    if _firebase_initialized:
        return

    # 1. Try to use FIREBASE_CREDENTIALS if provided (aliases to firebase-credentials, etc.)
    if settings.FIREBASE_CREDENTIALS:
        try:
            cert_dict = json.loads(settings.FIREBASE_CREDENTIALS)
            cred = credentials.Certificate(cert_dict)
            firebase_admin.initialize_app(cred)
            _firebase_initialized = True
            logger.info("Firebase Admin SDK initialized successfully using JSON string.")
            return
        except Exception as exc:
            logger.error("Failed to initialize Firebase Admin SDK using JSON string: %s", exc)
            # Fall back to file path if JSON string failed to load or initialize

    # 2. Fallback to FIREBASE_CREDENTIALS_PATH
    if not settings.FIREBASE_CREDENTIALS_PATH:
        logger.warning(
            "Neither FIREBASE_CREDENTIALS nor FIREBASE_CREDENTIALS_PATH is set. "
            "FCM push notifications are disabled."
        )
        return

    try:
        cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        firebase_admin.initialize_app(cred)
        _firebase_initialized = True
        logger.info("Firebase Admin SDK initialized successfully using file path.")
    except Exception as exc:
        logger.error("Failed to initialize Firebase Admin SDK using file path: %s", exc)



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
