from beanie import PydanticObjectId
from app.models.meeting import Meeting
from datetime import datetime, time

async def get_my_daily_programs(user_id: str, date: datetime | None = None) -> list[Meeting]:
    """
    Kullanıcının belirli bir güne (varsayılan bugün) ait programını (toplantılarını) getirir.
    """
    try:
        obj_id = PydanticObjectId(user_id)
    except Exception:
        return []

    # Eğer tarih verilmemişse bugünü baz al
    target_date = date or datetime.utcnow()
    
    # Günün başlangıcı (00:00:00) ve bitişi (23:59:59) aralığını belirle
    start_of_day = datetime.combine(target_date.date(), time.min)
    end_of_day = datetime.combine(target_date.date(), time.max)

    return await Meeting.find(
        Meeting.user_id == obj_id,
        Meeting.start_time >= start_of_day,
        Meeting.start_time <= end_of_day,
        Meeting.is_deleted == False
    ).sort(Meeting.start_time).to_list()

async def create_meeting(data: dict) -> Meeting:
    """Yeni bir toplantı kaydı oluşturur."""
    meeting = Meeting(**data)
    return await meeting.insert()