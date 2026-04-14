from fastapi import HTTPException
from backend.app.core.messages.error_message import COMMAND_NOT_FOUND
from backend.app.repositories.command import (
    create_command,
    get_command_by_id,
    get_commands_by_user,
    update_command,
    update_command_intent,
    update_command_parameters,
    soft_delete_command,
)
from backend.app.schemas.command import CommandCreate, CommandUpdate, CommandOut


async def create_command_service(data: CommandCreate) -> CommandOut:
    """Orchestrate command creation."""
    command = await create_command(data)
    return CommandOut.model_validate(command)


async def get_command_service(command_id: str) -> CommandOut:
    """Orchestrate command retrieval."""
    command = await get_command_by_id(command_id)
    if not command:
        raise HTTPException(status_code=404, detail=COMMAND_NOT_FOUND)
    return CommandOut.model_validate(command)


async def list_commands_by_user_service(user_id: str) -> list[CommandOut]:
    """Orchestrate listing commands for a user."""
    commands = await get_commands_by_user(user_id)
    return [CommandOut.model_validate(c) for c in commands]


async def update_command_service(command_id: str, data: CommandUpdate) -> CommandOut:
    """Orchestrate command update."""
    command = await update_command(command_id, data)
    if not command:
        raise HTTPException(status_code=404, detail=COMMAND_NOT_FOUND)
    return CommandOut.model_validate(command)


async def update_command_intent_service(command_id: str, intent: str, confidence: float) -> CommandOut:
    """Orchestrate command intent update."""
    command = await update_command_intent(command_id, intent, confidence)
    if not command:
        raise HTTPException(status_code=404, detail=COMMAND_NOT_FOUND)
    return CommandOut.model_validate(command)


async def update_command_parameters_service(command_id: str, parameters: dict) -> CommandOut:
    """Orchestrate command parameters update."""
    command = await update_command_parameters(command_id, parameters)
    if not command:
        raise HTTPException(status_code=404, detail=COMMAND_NOT_FOUND)
    return CommandOut.model_validate(command)


async def delete_command_service(command_id: str) -> None:
    """Orchestrate command soft deletion."""
    command = await soft_delete_command(command_id)
    if not command:
        raise HTTPException(status_code=404, detail=COMMAND_NOT_FOUND)
