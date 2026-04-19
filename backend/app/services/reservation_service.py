from fastapi import HTTPException
from app.core.messages.error_message import (
    RESERVATION_NOT_FOUND,
    RESERVATION_ALREADY_EXISTS
)
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

async def create_reservation_service(user_id: str, data: ReservationCreate) -> ReservationResponse:
    """
    Orchestrate reservation creation.
    1. Check for duplicate PNR
    2. Parse date
    3. Find/Create DailyProgram
    4. Save Reservation and Link to Program
    """
    # 1. Duplicate check by PNR
    pnr = data.details.get("pnr")
    if pnr:
        existing = await Reservation.find_one(
            Reservation.user_id == user_id,
            Reservation.details.pnr == pnr
        )
        if existing:
            raise HTTPException(status_code=409, detail=RESERVATION_ALREADY_EXISTS)

    # 2. Extract/Determine Start and End Dates
    start_d = None
    end_d = None
    
    if data.start_date:
        start_d = data.start_date.date()
    if data.end_date:
        end_d = data.end_date.date()
        
    # Fallback to fetching from details
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

    # 3. Save Reservation first
    data.user_id = user_id
    reservation = await create_reservation(data.model_dump())
    
    # 4. Link to Programs over the date range
    current_d = start_d
    while current_d <= end_d:
        program = await get_program_by_user_and_date(user_id, current_d)
        if not program:
            program_data = {
                "tarih": current_d,
                "kullanici_id": user_id,
                "ozet": DailyProgramSummary(task_sayisi=0, etkinlik_sayisi=0),
                "items": DailyProgramItems(tasks=[], etkinlikler=[])
            }
            program = await create_daily_program(program_data)

        # Check if already added to avoid duplicates if service is called weirdly
        if not any(str(r.id) == str(reservation.id) for r in program.items.etkinlikler):
            program.items.etkinlikler.append(reservation)
            program.ozet.etkinlik_sayisi += 1
            await program.save()
            
        current_d += timedelta(days=1)

    return ReservationResponse.model_validate(reservation)


async def get_reservation_service(reservation_id: str) -> ReservationResponse:
    """Orchestrate reservation retrieval."""
    reservation = await get_reservation_by_id(reservation_id)
    if not reservation:
        raise HTTPException(status_code=404, detail=RESERVATION_NOT_FOUND)
    return ReservationResponse.model_validate(reservation)


async def list_reservations_by_user_service(user_id: str) -> list[ReservationResponse]:
    """Orchestrate listing reservations for a user."""
    reservations = await get_reservation_by_user_id(user_id)
    return [ReservationResponse.model_validate(r) for r in reservations]


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
    return ReservationResponse.model_validate(updated_reservation)


async def delete_reservation_service(reservation_id: str) -> None:
    """Orchestrate reservation deletion."""
    reservation = await get_reservation_by_id(reservation_id)
    if not reservation:
        raise HTTPException(status_code=404, detail=RESERVATION_NOT_FOUND)
    await delete_reservation(reservation)
