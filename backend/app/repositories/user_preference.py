from beanie import PydanticObjectId
from backend.app.models.user_preference import UserPreference
from backend.app.schemas.user_preference import UserPreferenceUpdate


async def create_user_preference(data: dict) -> UserPreference:
    preference = UserPreference(**data)
    return await preference.insert()


async def get_user_preference_by_id(preference_id: str) -> UserPreference | None:
    return await UserPreference.get(PydanticObjectId(preference_id))


async def get_user_preference_by_user_id(user_id: str) -> UserPreference | None:
    return await UserPreference.find_one(
        UserPreference.user_id == PydanticObjectId(user_id)
    )


async def list_user_preferences() -> list[UserPreference]:
    return await UserPreference.find_all().to_list()


async def update_user_preference(
    preference: UserPreference,
    data: UserPreferenceUpdate
) -> UserPreference:
    update_data = data.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(preference, key, value)

    return await preference.save()


async def delete_user_preference(preference: UserPreference) -> None:
    await preference.delete()