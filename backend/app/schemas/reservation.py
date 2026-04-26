from typing import Any, Dict, Optional
from datetime import datetime
from pydantic import BaseModel
from app.schemas.base import BaseSchema

class ReservationBase(BaseModel):
    user_id: Optional[str] = None
    community_id: Optional[str] = None
    category: str
    title: str
    details: Dict[str, Any]
    is_shared: bool = False
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    status: str

class ReservationCreate(ReservationBase):
    pass

class ReservationUpdate(BaseModel):
    title: Optional[str] = None
    details: Optional[Dict[str, Any]] = None
    is_shared: Optional[bool] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    status: Optional[str] = None

class ReservationResponse(ReservationBase, BaseSchema):
    id: str

    class Config:
        from_attributes = True
        populate_by_name = True
