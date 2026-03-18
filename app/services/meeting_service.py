from fastapi import HTTPException
from app.core.messages.error_message import MEETING_NOT_FOUND
from app.repositories.meeting import (
    create_meeting,
    get_meeting_by_id,
    get_meetings_by_user,
    get_upcoming_meetings_by_user,
    update_meeting,
    soft_delete_meeting,
)
from app.schemas.meeting import MeetingCreate, MeetingUpdate, MeetingOut


async def create_meeting_service(data: MeetingCreate) -> MeetingOut:
    """Orchestrate meeting creation."""
    meeting = await create_meeting(data)
    return MeetingOut.model_validate(meeting)


async def get_meeting_service(meeting_id: str) -> MeetingOut:
    """Orchestrate meeting retrieval."""
    meeting = await get_meeting_by_id(meeting_id)
    if not meeting:
        raise HTTPException(status_code=404, detail=MEETING_NOT_FOUND)
    return MeetingOut.model_validate(meeting)


async def list_meetings_by_user_service(user_id: str) -> list[MeetingOut]:
    """Orchestrate listing meetings for a user."""
    meetings = await get_meetings_by_user(user_id)
    return [MeetingOut.model_validate(m) for m in meetings]


async def update_meeting_service(meeting_id: str, data: MeetingUpdate) -> MeetingOut:
    """Orchestrate meeting update."""
    meeting = await update_meeting(meeting_id, data)
    if not meeting:
        raise HTTPException(status_code=404, detail=MEETING_NOT_FOUND)
    return MeetingOut.model_validate(meeting)


async def delete_meeting_service(meeting_id: str) -> None:
    """Orchestrate meeting soft deletion."""
    meeting = await soft_delete_meeting(meeting_id)
    if not meeting:
        raise HTTPException(status_code=404, detail=MEETING_NOT_FOUND)


async def list_upcoming_meetings_by_user_service(user_id: str) -> list[MeetingOut]:
    """Orchestrate listing upcoming meetings for a user."""
    meetings = await get_upcoming_meetings_by_user(user_id)
    return [MeetingOut.model_validate(m) for m in meetings]
