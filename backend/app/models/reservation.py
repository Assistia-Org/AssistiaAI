from typing import Any, Dict, Optional
from datetime import datetime
from pydantic import Field
from app.models.base import BaseDocument

class Reservation(BaseDocument):
    id: str = Field(alias="_id")
    user_id: str
    community_id: Optional[str] = None
    category: str
    title: str
    details: Dict[str, Any]
    is_shared: bool = False
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    status: str

    class Settings:
        name = "reservations"
