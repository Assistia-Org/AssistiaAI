from fastapi import HTTPException
from app.core.messages.error_message import (
    RESERVATION_NOT_FOUND,
    RESERVATION_ALREADY_EXISTS,
    UNAUTHORIZED_COMMUNITY_ACTION
)
from app.core.logger import logger, EventType
from datetime import date, datetime, timedelta
from app.models.reservation import Reservation
from app.models.daily_program import DailyProgramSummary, DailyProgramItems
from app.repositories.reservation import (
    create_reservation,
    get_reservation_by_id,
    get_reservation_by_user_id,
    get_reservation_by_trip_id,
    update_reservation,
    delete_reservation,
)
from app.schemas.reservation import ReservationCreate, ReservationUpdate, ReservationResponse
from app.repositories.daily_program import (
    get_program_by_user_and_date,
    create_daily_program
)
from app.repositories.community import get_community_by_id
from app.models.user import User

async def create_reservation_service(current_user: User, data: ReservationCreate) -> ReservationResponse:
    """
    Orchestrate reservation creation and DailyProgram sync for all assigned users.
    1. Validate community ownership if community_id is provided.
    2. Determine target users.
    3. Duplicate check.
    4. Determine dates.
    5. Save Reservation.
    6. Link to Programs for all target users over the date range.
    7. Notify assigned users.
    """
    user_id = str(current_user.id)
    # 1. Validate community ownership
    community_name = None
    target_users = set()
    
    if data.community_id:
        community = await get_community_by_id(data.community_id)
        if not community:
            from app.core.messages.error_message import COMMUNITY_NOT_FOUND
            raise HTTPException(status_code=404, detail=COMMUNITY_NOT_FOUND)
        
        # Only owner can assign tasks to community or other members
        if community.owner_id != user_id:
            raise HTTPException(status_code=403, detail=UNAUTHORIZED_COMMUNITY_ACTION)
        
        community_name = community.name
        
        # Determine target users
        if not data.assigned_to:
            target_users = {str(m.user.id) for m in community.members}
        else:
            target_users = set(data.assigned_to)
    else:
        target_users = set(data.assigned_to) if data.assigned_to else {user_id}

    if not data.community_id and user_id not in target_users:
        target_users.add(user_id)

    # 2. Duplicate check by PNR
    pnr = data.details.get("pnr")
    if pnr:
        # Check if ANY of the target users already has this PNR? 
        # For simplicity, check if the creator has it or if ANY exists.
        # Requirements didn't specify cross-user uniqueness.
        existing = await Reservation.find_one(
            Reservation.details.pnr == pnr
        )
        if existing:
            raise HTTPException(status_code=409, detail=RESERVATION_ALREADY_EXISTS)

    # 3. Extract/Determine Start and End Dates
    start_d = None
    end_d = None
    
    if data.start_date:
        start_d = data.start_date.date()
    if data.end_date:
        end_d = data.end_date.date()
        
    target_date_str = data.details.get("date") or data.details.get("check_in")
    try:
        if target_date_str and not start_d:
            start_d = datetime.strptime(target_date_str, "%Y-%m-%d").date()
    except ValueError:
        pass
    
    if not start_d:
        start_d = date.today()
    if not end_d:
        end_d = start_d
        
    if end_d < start_d:
        end_d = start_d

    # 4. Save Reservation
    data.user_id = user_id # Keep track of who created it
    data.assigned_to = list(target_users)
    reservation = await create_reservation(data.model_dump())
    
    # 5. Link to Programs over the date range for ALL target users
    for t_user_id in target_users:
        current_d = start_d
        while current_d <= end_d:
            program = await get_program_by_user_and_date(t_user_id, current_d)
            if not program:
                program_data = {
                    "tarih": current_d,
                    "kullanici_id": t_user_id,
                    "ozet": DailyProgramSummary(task_sayisi=0, etkinlik_sayisi=0),
                    "items": DailyProgramItems(tasks=[], etkinlikler=[])
                }
                program = await create_daily_program(program_data)

            if not any(str(r.id) == str(reservation.id) for r in program.items.etkinlikler):
                program.items.etkinlikler.append(reservation)
                program.ozet.etkinlik_sayisi += 1
                await program.save()
                
            current_d += timedelta(days=1)

    # 6. Notify assigned users
    from app.services.notification_service import create_notification_service
    from app.models.notification import NotificationType
    
    for t_user_id in target_users:
        if t_user_id != user_id:
            await create_notification_service(
                user_id=t_user_id,
                type=NotificationType.INVITATION,
                title="Yeni Rezervasyon Atandı",
                body=f"{current_user.display_name} sana bir rezervasyon atadı: {reservation.title}",
                metadata={"reservation_id": str(reservation.id), "community_id": data.community_id},
            )

    response = ReservationResponse.model_validate(reservation)
    response.community_name = community_name
    await logger.info(
        EventType.RESERVATION_CREATE,
        f"Rezervasyon oluşturuldu: {reservation.title}",
        user_id=user_id,
        extra={
            "reservation_id": str(reservation.id),
            "community_id": data.community_id,
            "assigned_to": list(target_users),
        },
    )
    return response


async def get_reservation_service(reservation_id: str) -> ReservationResponse:
    """Orchestrate reservation retrieval."""
    reservation = await get_reservation_by_id(reservation_id)
    if not reservation:
        raise HTTPException(status_code=404, detail=RESERVATION_NOT_FOUND)
    
    response = ReservationResponse.model_validate(reservation)
    if reservation.community_id:
        community = await get_community_by_id(reservation.community_id)
        if community:
            response.community_name = community.name
    return response


async def list_reservations_by_user_service(user_id: str) -> list[ReservationResponse]:
    """Orchestrate listing reservations for a user."""
    reservations = await get_reservation_by_user_id(user_id)
    responses = []
    for r in reservations:
        res = ReservationResponse.model_validate(r)
        if r.community_id:
            community = await get_community_by_id(r.community_id)
            if community:
                res.community_name = community.name
        responses.append(res)
    return responses


async def list_reservations_by_trip_service(trip_id: str) -> list[ReservationResponse]:
    """Orchestrate listing reservations for a trip."""
    reservations = await get_reservation_by_trip_id(trip_id)
    return [ReservationResponse.model_validate(r) for r in reservations]


async def update_reservation_service(reservation_id: str, data: ReservationUpdate) -> ReservationResponse:
    """Orchestrate reservation update."""
    reservation = await get_reservation_by_id(reservation_id)
    if not reservation:
        raise HTTPException(status_code=404, detail=RESERVATION_NOT_FOUND)
    
    updated_reservation = await update_reservation(reservation, data.model_dump(exclude_unset=True))
    await logger.info(
        EventType.RESERVATION_UPDATE,
        "Rezervasyon güncellendi",
        user_id=str(reservation.user_id),
        extra={"reservation_id": reservation_id}
    )
    return ReservationResponse.model_validate(updated_reservation)


async def delete_reservation_service(reservation_id: str, current_user: User) -> None:
    """
    Orchestrate reservation deletion and remove from linked daily programs.
    - If current_user is the creator: Delete the reservation globally and remove from ALL users' programs.
    - If current_user is just assigned: Remove current_user from assigned_to and only from their own program.
    """
    reservation = await get_reservation_by_id(reservation_id)
    if not reservation:
        raise HTTPException(status_code=404, detail=RESERVATION_NOT_FOUND)

    user_id = str(current_user.id)
    creator_id = str(reservation.user_id)
    is_creator = creator_id == user_id

    # Determine the date range for DailyProgram cleanup
    start_d = reservation.start_date.date() if reservation.start_date else date.today()
    end_d = reservation.end_date.date() if reservation.end_date else start_d
    if end_d < start_d:
        end_d = start_d

    if is_creator:
        # 1. Cleanup DailyProgram for ALL assigned users over the date range
        for assigned_user_id in reservation.assigned_to:
            current_d = start_d
            while current_d <= end_d:
                program = await get_program_by_user_and_date(assigned_user_id, current_d)
                if program:
                    original_len = len(program.items.etkinlikler)
                    program.items.etkinlikler = [r for r in program.items.etkinlikler if str(getattr(r, "id", r)) != reservation_id]
                    
                    if len(program.items.etkinlikler) < original_len:
                        program.ozet.etkinlik_sayisi -= (original_len - len(program.items.etkinlikler))
                        if program.ozet.etkinlik_sayisi < 0:
                            program.ozet.etkinlik_sayisi = 0
                        await program.save()
                current_d += timedelta(days=1)

        # 2. Delete the reservation record itself
        await delete_reservation(reservation)
        await logger.warning(
            EventType.RESERVATION_DELETE,
            f"Rezervasyon lider tarafından herkes için silindi: {reservation_id}",
            extra={"reservation_id": reservation_id, "creator_id": user_id},
        )
    else:
        # 1. Cleanup DailyProgram ONLY for the current user over the date range
        current_d = start_d
        while current_d <= end_d:
            program = await get_program_by_user_and_date(user_id, current_d)
            if program:
                original_len = len(program.items.etkinlikler)
                program.items.etkinlikler = [r for r in program.items.etkinlikler if str(getattr(r, "id", r)) != reservation_id]
                
                if len(program.items.etkinlikler) < original_len:
                    program.ozet.etkinlik_sayisi -= (original_len - len(program.items.etkinlikler))
                    if program.ozet.etkinlik_sayisi < 0:
                        program.ozet.etkinlik_sayisi = 0
                    await program.save()
            current_d += timedelta(days=1)

        # 2. Remove the user from the assigned_to list of the reservation
        if user_id in reservation.assigned_to:
            reservation.assigned_to.remove(user_id)
            await reservation.save()

        await logger.info(
            EventType.RESERVATION_UPDATE,
            f"Kullanıcı rezervasyonu kendi listesinden sildi: {reservation_id}",
            extra={"reservation_id": reservation_id, "user_id": user_id},
        )
