from fastapi import HTTPException
from app.core.messages.error_message import USER_PREFERENCE_NOT_FOUND
from app.repositories.user_preference import (
    create_user_preference,
    get_user_preference_by_id,
    get_user_preference_by_user_id,
    list_user_preferences,
    update_user_preference,
    delete_user_preference,
)
from app.schemas.user_preference import UserPreferenceCreate, UserPreferenceUpdate, UserPreferenceOut


async def create_user_preference_service(data: UserPreferenceCreate) -> UserPreferenceOut:
    """Orchestrate user preference creation."""
    preference_data = data.model_dump()
    preference = await create_user_preference(preference_data)
    return UserPreferenceOut.model_validate(preference)


async def get_user_preference_service(preference_id: str) -> UserPreferenceOut:
    """Orchestrate user preference retrieval by ID."""
    preference = await get_user_preference_by_id(preference_id)
    if not preference:
        raise HTTPException(status_code=404, detail=USER_PREFERENCE_NOT_FOUND)
    return UserPreferenceOut.model_validate(preference)


async def get_user_preference_by_user_service(user_id: str) -> UserPreferenceOut:
    """Orchestrate user preference retrieval by user ID."""
    preference = await get_user_preference_by_user_id(user_id)
    if not preference:
        raise HTTPException(status_code=404, detail=USER_PREFERENCE_NOT_FOUND)
    return UserPreferenceOut.model_validate(preference)


async def list_user_preferences_service() -> list[UserPreferenceOut]:
    """Orchestrate listing all user preferences."""
    preferences = await list_user_preferences()
    return [UserPreferenceOut.model_validate(p) for p in preferences]


async def update_user_preference_service(user_id: str, data: UserPreferenceUpdate) -> UserPreferenceOut:
    """Orchestrate user preference update by user ID."""
    preference = await get_user_preference_by_user_id(user_id)
    if not preference:
        raise HTTPException(status_code=404, detail=USER_PREFERENCE_NOT_FOUND)
    
    updated_preference = await update_user_preference(preference, data)
    return UserPreferenceOut.model_validate(updated_preference)


async def delete_user_preference_service(user_id: str) -> None:
    """Orchestrate user preference deletion by user ID."""
    preference = await get_user_preference_by_user_id(user_id)
    if not preference:
        raise HTTPException(status_code=404, detail=USER_PREFERENCE_NOT_FOUND)
    await delete_user_preference(preference)
