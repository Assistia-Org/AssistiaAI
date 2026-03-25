from datetime import datetime
from fastapi import HTTPException
from app.core.messages.error_message import INTEGRATION_NOT_FOUND
from app.models.integration import IntegrationService
from app.repositories.integration import (
    create_integration,
    get_integration_by_id,
    get_integrations_by_user,
    get_user_service_integration,
    update_integration,
    update_tokens,
    soft_delete_integration,
)
from app.schemas.integration import IntegrationCreate, IntegrationUpdate, IntegrationOut


async def create_integration_service(data: IntegrationCreate) -> IntegrationOut:
    """Orchestrate integration creation."""
    integration = await create_integration(data)
    return IntegrationOut.model_validate(integration)


async def get_integration_service(integration_id: str) -> IntegrationOut:
    """Orchestrate integration retrieval."""
    integration = await get_integration_by_id(integration_id)
    if not integration:
        raise HTTPException(status_code=404, detail=INTEGRATION_NOT_FOUND)
    return IntegrationOut.model_validate(integration)


async def list_integrations_by_user_service(user_id: str) -> list[IntegrationOut]:
    """Orchestrate listing integrations for a user."""
    integrations = await get_integrations_by_user(user_id)
    return [IntegrationOut.model_validate(i) for i in integrations]


async def get_user_service_integration_service(user_id: str, service: IntegrationService) -> IntegrationOut:
    """Orchestrate retrieving a specific service integration for a user."""
    integration = await get_user_service_integration(user_id, service)
    if not integration:
        raise HTTPException(status_code=404, detail=INTEGRATION_NOT_FOUND)
    return IntegrationOut.model_validate(integration)


async def update_integration_service(integration_id: str, data: IntegrationUpdate) -> IntegrationOut:
    """Orchestrate integration update."""
    integration = await update_integration(integration_id, data)
    if not integration:
        raise HTTPException(status_code=404, detail=INTEGRATION_NOT_FOUND)
    return IntegrationOut.model_validate(integration)


async def update_tokens_service(
    integration_id: str, 
    access_token: str, 
    refresh_token: str | None = None, 
    expires_at: datetime | None = None
) -> IntegrationOut:
    """Orchestrate integration token update."""
    integration = await update_tokens(integration_id, access_token, refresh_token, expires_at)
    if not integration:
        raise HTTPException(status_code=404, detail=INTEGRATION_NOT_FOUND)
    return IntegrationOut.model_validate(integration)


async def delete_integration_service(integration_id: str) -> None:
    """Orchestrate integration soft deletion."""
    integration = await soft_delete_integration(integration_id)
    if not integration:
        raise HTTPException(status_code=404, detail=INTEGRATION_NOT_FOUND)
