from fastapi import HTTPException
from app.core.messages.error_message import TRIP_NOT_FOUND
from app.repositories.trip import (
    create_trip,
    get_trip_by_id,
    get_trips_by_user_id,
    list_trips,
    update_trip,
    delete_trip,
)
from app.schemas.trip import TripCreate, TripUpdate, TripOut


async def create_trip_service(data: TripCreate) -> TripOut:
    """Orchestrate trip creation."""
    trip = await create_trip(data)
    return TripOut.model_validate(trip)


async def get_trip_service(trip_id: str) -> TripOut:
    """Orchestrate trip retrieval."""
    trip = await get_trip_by_id(trip_id)
    if not trip:
        raise HTTPException(status_code=404, detail=TRIP_NOT_FOUND)
    return TripOut.model_validate(trip)


async def list_trips_by_user_service(user_id: str) -> list[TripOut]:
    """Orchestrate listing trips for a user."""
    trips = await get_trips_by_user_id(user_id)
    return [TripOut.model_validate(t) for t in trips]


async def list_all_trips_service() -> list[TripOut]:
    """Orchestrate listing all trips."""
    trips = await list_trips()
    return [TripOut.model_validate(t) for t in trips]


async def update_trip_service(trip_id: str, data: TripUpdate) -> TripOut:
    """Orchestrate trip update."""
    trip = await get_trip_by_id(trip_id)
    if not trip:
        raise HTTPException(status_code=404, detail=TRIP_NOT_FOUND)
    
    updated_trip = await update_trip(trip, data)
    return TripOut.model_validate(updated_trip)


async def delete_trip_service(trip_id: str) -> None:
    """Orchestrate trip deletion."""
    trip = await get_trip_by_id(trip_id)
    if not trip:
        raise HTTPException(status_code=404, detail=TRIP_NOT_FOUND)
    await delete_trip(trip)
