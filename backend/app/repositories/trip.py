from beanie import PydanticObjectId
from backend.app.models.trip import Trip
from backend.app.schemas.trip import TripCreate, TripUpdate


async def create_trip(data: TripCreate) -> Trip:
    trip = Trip(**data.model_dump())
    return await trip.insert()


async def get_trip_by_id(trip_id: str) -> Trip | None:
    return await Trip.get(PydanticObjectId(trip_id))


async def get_trips_by_user_id(user_id: str) -> list[Trip]:
    return await Trip.find(
        Trip.user_id == PydanticObjectId(user_id)
    ).to_list()


async def list_trips() -> list[Trip]:
    return await Trip.find_all().to_list()


async def update_trip(trip: Trip, data: TripUpdate) -> Trip:
    update_data = data.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(trip, key, value)

    return await trip.save()


async def delete_trip(trip: Trip) -> None:
    await trip.delete()