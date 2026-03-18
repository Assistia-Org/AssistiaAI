from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from datetime import datetime
from beanie import PydanticObjectId
from app.models.reservation import ReservationType

class ReservationBase(BaseModel):
    type: ReservationType
    provider: str
    reservation_details: Dict[str, Any] = Field(default_factory=dict)
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None

class ReservationCreate(ReservationBase):
    user_id: PydanticObjectId
    trip_id: PydanticObjectId

class ReservationUpdate(BaseModel):
    type: Optional[ReservationType] = None
    provider: Optional[str] = None
    reservation_details: Optional[Dict[str, Any]] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None

class ReservationOut(ReservationBase):
    id: PydanticObjectId = Field(alias="_id")
    user_id: PydanticObjectId
    trip_id: PydanticObjectId
    is_deleted: bool

    class Config:
        populate_by_name = True
