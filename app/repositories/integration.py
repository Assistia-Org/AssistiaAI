from beanie import PydanticObjectId
from datetime import datetime

from app.models.integration import Integration, IntegrationService
from app.schemas.integration import IntegrationCreate, IntegrationUpdate


async def create_integration(data: IntegrationCreate) -> Integration:
    integration = Integration(**data.model_dump())
    return await integration.insert()


async def get_integration_by_id(integration_id: str) -> Integration | None:
    try:
        obj_id = PydanticObjectId(integration_id)
    except Exception:
        return None

    integration = await Integration.get(obj_id)

    if not integration:
        return None

    if getattr(integration, "is_deleted", False):
        return None

    return integration


async def get_integrations_by_user(user_id: str) -> list[Integration]:
    try:
        obj_id = PydanticObjectId(user_id)
    except Exception:
        return []

    return await Integration.find(
        Integration.user_id == obj_id,
        Integration.is_deleted == False
    ).to_list()


async def get_user_service_integration(
    user_id: str,
    service: IntegrationService
) -> Integration | None:

    try:
        obj_id = PydanticObjectId(user_id)
    except Exception:
        return None

    return await Integration.find_one(
        Integration.user_id == obj_id,
        Integration.service == service,
        Integration.is_deleted == False
    )


async def update_integration(
    integration_id: str,
    data: IntegrationUpdate
) -> Integration | None:

    integration = await get_integration_by_id(integration_id)

    if not integration:
        return None

    update_data = data.model_dump(exclude_unset=True)

    for field, value in update_data.items():
        setattr(integration, field, value)

    await integration.save()

    return integration


async def update_tokens(
    integration_id: str,
    access_token: str,
    refresh_token: str | None,
    expires_at: datetime | None
) -> Integration | None:

    integration = await get_integration_by_id(integration_id)

    if not integration:
        return None

    integration.access_token = access_token
    integration.refresh_token = refresh_token
    integration.expires_at = expires_at

    await integration.save()

    return integration


async def soft_delete_integration(integration_id: str) -> Integration | None:

    integration = await get_integration_by_id(integration_id)

    if not integration:
        return None

    integration.is_deleted = True
    await integration.save()

    return integration