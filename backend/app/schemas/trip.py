from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from beanie import PydanticObjectId

class TripBase(BaseModel):
    title: str
    destination: str
    start_date: datetime
    end_date: datetime
    status: str = "planned"
    notes: Optional[str] = None

class TripCreate(TripBase):
    user_id: PydanticObjectId

class TripUpdate(BaseModel):
    title: Optional[str] = None
    destination: Optional[str] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    status: Optional[str] = None
    notes: Optional[str] = None

class TripOut(TripBase):
    id: PydanticObjectId = Field(alias="_id")
    user_id: PydanticObjectId
    is_deleted: bool

    class Config:
        populate_by_name = True
