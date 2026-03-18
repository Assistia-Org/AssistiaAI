from fastapi import HTTPException
from app.core.messages.error_message import RESERVATION_NOT_FOUND
from app.repositories.reservation import (
    create_reservation,
    get_reservation_by_id,
    get_reservation_by_user_id,
    get_reservation_by_trip_id,
    update_reservation,
    delete_reservation,
)
from app.schemas.reservation import ReservationCreate, ReservationUpdate, ReservationOut


async def create_reservation_service(data: ReservationCreate) -> ReservationOut:
    """Orchestrate reservation creation."""
    reservation = await create_reservation(data)
    return ReservationOut.model_validate(reservation)


async def get_reservation_service(reservation_id: str) -> ReservationOut:
    """Orchestrate reservation retrieval."""
    reservation = await get_reservation_by_id(reservation_id)
    if not reservation:
        raise HTTPException(status_code=404, detail=RESERVATION_NOT_FOUND)
    return ReservationOut.model_validate(reservation)


async def list_reservations_by_user_service(user_id: str) -> list[ReservationOut]:
    """Orchestrate listing reservations for a user."""
    reservations = await get_reservation_by_user_id(user_id)
    return [ReservationOut.model_validate(r) for r in reservations]


async def list_reservations_by_trip_service(trip_id: str) -> list[ReservationOut]:
    """Orchestrate listing reservations for a trip."""
    reservations = await get_reservation_by_trip_id(trip_id)
    return [ReservationOut.model_validate(r) for r in reservations]


async def update_reservation_service(reservation_id: str, data: ReservationUpdate) -> ReservationOut:
    """Orchestrate reservation update."""
    reservation = await get_reservation_by_id(reservation_id)
    if not reservation:
        raise HTTPException(status_code=404, detail=RESERVATION_NOT_FOUND)
    
    updated_reservation = await update_reservation(reservation, data)
    return ReservationOut.model_validate(updated_reservation)


async def delete_reservation_service(reservation_id: str) -> None:
    """Orchestrate reservation deletion."""
    reservation = await get_reservation_by_id(reservation_id)
    if not reservation:
        raise HTTPException(status_code=404, detail=RESERVATION_NOT_FOUND)
    await delete_reservation(reservation)
