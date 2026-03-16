from beanie import PydanticObjectId
from app.models.meeting import Meeting
from app.schemas.meeting import MeetingCreate , MeetingUpdate

async def create_meeting(data: MeetingCreate) -> Meeting:
    meeting = Meeting(**data.model_dump())
    return await meeting.insert()

async def get_meeting_by_id(meeting_id: str) -> Meeting | None:
    try:
        obj_id = PydanticObjectId(meeting_id)
    except Exception:
        return None

    meeting = await Meeting.get(obj_id)

    if not meeting:
        return None

    if getattr(meeting, "is_deleted", False):
        return None

    return meeting

async def get_meetings_by_user(user_id: str) -> list[Meeting]:
    try:
        obj_id = PydanticObjectId(user_id)
    except Exception:
        return []

    return await Meeting.find(
        Meeting.user_id == obj_id,
        Meeting.is_deleted == False
    ).sort(Meeting.start_time).to_list()


async def update_meeting(
    meeting_id: str,
    data: MeetingUpdate
) -> Meeting | None:
    meeting = await get_meeting_by_id(meeting_id)
    if not meeting:
        return None

    update_data = data.model_dump(exclude_unset=True)

    for field, value in update_data.items():
        setattr(meeting, field, value)

    await meeting.save()
    return meeting


async def soft_delete_meeting(meeting_id: str) -> Meeting | None:
    meeting = await get_meeting_by_id(meeting_id)
    if not meeting:
        return None

    meeting.is_deleted = True
    await meeting.save()
    return meeting


async def get_upcoming_meetings_by_user(user_id: str) -> list[Meeting]:
    try:
        obj_id = PydanticObjectId(user_id)
    except Exception:
        return []

    now = datetime.utcnow()

    return await Meeting.find(
        Meeting.user_id == obj_id,
        Meeting.start_time >= now,
        Meeting.is_deleted == False
    ).sort(Meeting.start_time).to_list()