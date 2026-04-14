from beanie import PydanticObjectId

from backend.app.models.command import Command
from backend.app.schemas.command import CommandCreate, CommandUpdate


async def create_command(data: CommandCreate) -> Command:
    command = Command(**data.model_dump())
    return await command.insert()


async def get_command_by_id(command_id: str) -> Command | None:
    try:
        obj_id = PydanticObjectId(command_id)
    except Exception:
        return None

    command = await Command.get(obj_id)

    if not command:
        return None

    if getattr(command, "is_deleted", False):
        return None

    return command


async def get_commands_by_user(user_id: str) -> list[Command]:
    try:
        obj_id = PydanticObjectId(user_id)
    except Exception:
        return []

    return await Command.find(
        Command.user_id == obj_id,
        Command.is_deleted == False
    ).sort(-Command.timestamp).to_list()


async def update_command(
    command_id: str,
    data: CommandUpdate
) -> Command | None:

    command = await get_command_by_id(command_id)

    if not command:
        return None

    update_data = data.model_dump(exclude_unset=True)

    for field, value in update_data.items():
        setattr(command, field, value)

    await command.save()

    return command


async def update_command_intent(
    command_id: str,
    intent: str,
    confidence: float
) -> Command | None:

    command = await get_command_by_id(command_id)

    if not command:
        return None

    command.intent = intent
    command.confidence = confidence

    await command.save()

    return command


async def update_command_parameters(
    command_id: str,
    parameters: dict
) -> Command | None:

    command = await get_command_by_id(command_id)

    if not command:
        return None

    command.parameters = parameters

    await command.save()

    return command


async def soft_delete_command(command_id: str) -> Command | None:

    command = await get_command_by_id(command_id)

    if not command:
        return None

    command.is_deleted = True

    await command.save()

    return command