import json
from fastapi import HTTPException
from app.core.messages.error_message import USER_NOT_FOUND, DUPLICATE_EMAIL
from app.repositories.user import (
    delete_user,
    get_user_by_email,
    get_user_by_id,
    list_users,
    update_user,
    update_fcm_token,
)
from app.schemas.user import UserResponse, UserUpdate
from app.core.logger import logger, EventType
from app.core.redis import set_redis_value


async def get_user_service(user_id: str) -> UserResponse:
    """Orchestrate user retrieval."""
    user = await get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail=USER_NOT_FOUND)
    return UserResponse.model_validate(user)


async def get_user_by_email_service(email: str) -> UserResponse:
    """Orchestrate user retrieval by email."""
    user = await get_user_by_email(email)
    if not user:
        raise HTTPException(status_code=404, detail=USER_NOT_FOUND)
    return UserResponse.model_validate(user)


async def list_users_service() -> list[UserResponse]:
    """Orchestrate user listing."""
    users = await list_users()
    return [UserResponse.model_validate(u) for u in users]


async def update_user_service(user_id: str, data: UserUpdate) -> UserResponse:
    """Orchestrate user update with security utilities."""
    user = await get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail=USER_NOT_FOUND)
    
    if data.email:
        existing_user = await get_user_by_email(data.email)
        if existing_user and str(existing_user.id) != str(user.id):
            raise HTTPException(status_code=400, detail=DUPLICATE_EMAIL)
    
    update_data = data.model_dump(exclude_unset=True)
        
    updated_user = await update_user(user, update_data)
    # Redis cache'i yenile (username/email değişmiş olabilir)
    cache_val = json.dumps({
        "username": updated_user.username or "",
        "email":    updated_user.email or "",
    })
    await set_redis_value(f"user_cache:{user_id}", cache_val, expire=86400)
    await logger.info(
        EventType.USER_UPDATE,
        "Kullanıcı profili güncellendi",
        user_id=user_id,
        username=updated_user.username or "",
        email=updated_user.email or "",
        extra={"fields": list(update_data.keys())},
    )
    return UserResponse.model_validate(updated_user)


async def update_me_service(current_user_id: str, data: UserUpdate) -> UserResponse:
    """Update the currently authenticated user."""
    return await update_user_service(current_user_id, data)


async def delete_user_service(user_id: str) -> None:
    """Orchestrate user deletion."""
    user = await get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail=USER_NOT_FOUND)
    await delete_user(user)
    await logger.warning(
        EventType.USER_DELETE,
        "Kullanıcı hesabı silindi",
        user_id=user_id,
    )


async def update_fcm_token_service(user_id: str, fcm_token: str) -> None:
    """
    Save or refresh the FCM device token for the authenticated user.
    Called by Flutter after every successful login.
    """
    updated = await update_fcm_token(user_id, fcm_token)
    if not updated:
        raise HTTPException(status_code=404, detail=USER_NOT_FOUND)
