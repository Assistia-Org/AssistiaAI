from beanie import Document, PydanticObjectId
from pydantic import Field
from typing import Optional, Dict, Any
from datetime import datetime
from enum import Enum
from .base import SoftDeleteMixin

class ReservationType(str, Enum):
    flight = "flight"
    hotel = "hotel"
    restaurant = "restaurant"
    event = "event"

class Reservation(Document, SoftDeleteMixin):
    user_id: PydanticObjectId
    trip_id: PydanticObjectId
    type: ReservationType
    provider: str
    reservation_details: Dict[str, Any] = Field(default_factory=dict)
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None

    class Settings:
        name = "reservations"
