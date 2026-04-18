from typing import List, Optional
from app.models.reservation import Reservation
from app.db import get_database

class ReservationRepository:
    def __init__(self):
        self.db = get_database()
        self.collection = self.db["reservations"]

    # CREATE
    async def create(self, reservation: Reservation) -> Reservation:
        data = reservation.dict(by_alias=True)
        await self.collection.insert_one(data)
        return reservation

    # GET BY ID
    async def get_by_id(self, reservation_id: str) -> Optional[Reservation]:
        doc = await self.collection.find_one({"_id": reservation_id})
        if doc:
            return Reservation(**doc)
        return None

    # LIST ALL
    async def list(self) -> List[Reservation]:
        reservations = []
        cursor = self.collection.find()

        async for doc in cursor:
            reservations.append(Reservation(**doc))

        return reservations

    # LIST BY USER
    async def list_by_user(self, user_id: str) -> List[Reservation]:
        reservations = []
        cursor = self.collection.find({"user_id": user_id})

        async for doc in cursor:
            reservations.append(Reservation(**doc))

        return reservations

    # LIST BY COMMUNITY
    async def list_by_community(self, community_id: str) -> List[Reservation]:
        reservations = []
        cursor = self.collection.find({"community_id": community_id})

        async for doc in cursor:
            reservations.append(Reservation(**doc))

        return reservations

    # UPDATE STATUS
    async def update_status(self, reservation_id: str, status: str):
        await self.collection.update_one(
            {"_id": reservation_id},
            {"$set": {"status": status}}
        )

    # DELETE
    async def delete(self, reservation_id: str):
        await self.collection.delete_one({"_id": reservation_id})

    async def get_my_reservations(user_id: str, res_type: str | None = None) -> list[Reservation]:
        try:
            obj_id = PydanticObjectId(user_id)
        except Exception:
            return []

        query = {"user_id": obj_id, "is_deleted": False}
        if res_type:
            query["type"] = res_type

        return await Reservation.find(query).sort(-Reservation.start_time).to_list()