from fastapi import APIRouter, status
from app.schemas.meeting import MeetingCreate, MeetingOut, MeetingUpdate
from app.services.meeting_service import (
    create_meeting_service,
    delete_meeting_service,
    get_meeting_service,
    list_meetings_by_user_service,
    list_upcoming_meetings_by_user_service,
    update_meeting_service,
)

router = APIRouter(prefix="/meetings", tags=["meetings"])


@router.post("/", response_model=MeetingOut, status_code=status.HTTP_201_CREATED)
async def create_meeting(data: MeetingCreate) -> MeetingOut:
    """
    Toplantı oluşturma endpoint'i.
    Sisteme yeni bir toplantı (ve katılımcılar vb.) kaydı ekler.
    """
    return await create_meeting_service(data)


@router.get("/{meeting_id}", response_model=MeetingOut, status_code=status.HTTP_200_OK)
async def get_meeting(meeting_id: str) -> MeetingOut:
    """
    Toplantı detay getirme endpoint'i.
    Belirli bir ID'ye sahip toplantının tüm bilgilerini ve linklerini getirir.
    """
    return await get_meeting_service(meeting_id)


@router.get("/user/{user_id}", response_model=list[MeetingOut], status_code=status.HTTP_200_OK)
async def list_user_meetings(user_id: str) -> list[MeetingOut]:
    """
    Kullanıcının bağlantılı olduğu tüm toplantıları listeleme endpoint'i.
    Kullanıcıya özel olan toplantı ajandasını topluca döner.
    """
    return await list_meetings_by_user_service(user_id)


@router.get("/user/{user_id}/upcoming", response_model=list[MeetingOut], status_code=status.HTTP_200_OK)
async def list_upcoming_meetings(user_id: str) -> list[MeetingOut]:
    """
    Yaklaşan toplantıları listeleme endpoint'i.
    Kullanıcının sadece gelecekte olan toplantılarını listeler.
    """
    return await list_upcoming_meetings_by_user_service(user_id)


@router.patch("/{meeting_id}", response_model=MeetingOut, status_code=status.HTTP_200_OK)
async def update_meeting(meeting_id: str, data: MeetingUpdate) -> MeetingOut:
    """
    Toplantı güncelleme endpoint'i.
    Toplantı detaylarındaki saatleri, platformu veya linki değiştirir.
    """
    return await update_meeting_service(meeting_id, data)


@router.delete("/{meeting_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_meeting(meeting_id: str) -> None:
    """
    Toplantı silme (iptal etme) endpoint'i.
    Toplantıyı soft-delete yönetimiyle silerek iptal edildi kabul eder.
    """
    await delete_meeting_service(meeting_id)
