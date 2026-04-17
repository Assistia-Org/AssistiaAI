from typing import List, Optional
from app.models.reservation import Reservation

async def create_reservation(reservation_data: dict) -> Reservation:
    """Create a new reservation and return the inserted document."""
    reservation = Reservation(**reservation_data)
    return await reservation.insert()

async def get_reservation_by_id(reservation_id: str) -> Optional[Reservation]:
    """Return reservation by ID or None if not found."""
    return await Reservation.find_one(Reservation.id == reservation_id)

async def list_reservations() -> List[Reservation]:
    """Return all reservations."""
    return await Reservation.find_all().to_list()

async def get_reservation_by_user_id(user_id: str) -> List[Reservation]:
    """Return reservations for a specific user."""
    return await Reservation.find(Reservation.user_id == user_id).to_list()

async def get_reservation_by_trip_id(trip_id: str) -> List[Reservation]:
    """Return reservations for a specific trip."""
    # Maps to get_reservation_by_trip_id used in reservation_service.py
    return await Reservation.find(Reservation.trip_id == trip_id).to_list()

async def list_reservations_by_community(community_id: str) -> List[Reservation]:
    """Return reservations for a specific community."""
    return await Reservation.find(Reservation.community_id == community_id).to_list()

async def update_reservation_status(reservation_id: str, status: str) -> bool:
    """Update reservation status."""
    reservation = await get_reservation_by_id(reservation_id)
    if not reservation:
        return False
    reservation.status = status
    await reservation.save()
    return True

async def update_reservation(reservation: Reservation, data: dict) -> Reservation:
    """Update reservation document with provided data."""
    for key, value in data.items():
        if hasattr(reservation, key):
            setattr(reservation, key, value)
    return await reservation.save()

async def delete_reservation(reservation: Reservation) -> bool:
    """Delete a reservation document."""
    await reservation.delete()
    return True
