from typing import Any, Dict, Optional
from pydantic import BaseModel
from app.schemas.base import BaseSchema

class ReservationBase(BaseModel):
    user_id: str
    community_id: str
    category: str
    title: str
    details: Dict[str, Any]
    is_shared: bool = False
    status: str

class ReservationCreate(ReservationBase):
    id: str

class ReservationUpdate(BaseModel):
    title: Optional[str] = None
    details: Optional[Dict[str, Any]] = None
    is_shared: Optional[bool] = None
    status: Optional[str] = None

class ReservationResponse(ReservationBase, BaseSchema):
    id: str

    class Config:
        from_attributes = True
        populate_by_name = True
