from beanie import PydanticObjectId
from app.models.reservation import Reservation
from app.schemas.reservation import ReservationCreate, ReservationUpdate

async def create_reservation(data: ReservationCreate)-> Reservation:
    reservation = Reservation(**data.model_dump())
    return await reservation.insert()

async def get_reservation_by_id(reservation_id:str) -> Reservation | None:
    return await Reservation.get(PydanticObjectId(reservation_id))

async def get_reservation_by_user_id(user_id:str) -> list[Reservation]:
    return await Reservation.find(
        Reservation.user_id == PydanticObjectId(user_id)
    ).to_list()

async def get_reservation_by_trip_id(trip_id:str) -> list[Reservation]:
    return await Reservation.find(
        Reservation.trip_id == PydanticObjectId(trip_id)
    ).to_list()

async def update_reservation( reservation: Reservation, data: ReservationUpdate)-> Reservation:
    update_data = data.model_dump(exclude_unset = True)

    for key,value in update_data.items():
        setattr(reservation,key,value)
    
    return await reservation.save()

async def delete_reservation(reservation: Reservation) -> None:
    await reservation.delete()