from typing import Any, Dict
from pydantic import Field
from app.models.base import BaseDocument

class Reservation(BaseDocument):
    id: str = Field(alias="_id")
    user_id: str
    community_id: str
    category: str
    title: str
    details: Dict[str, Any]
    is_shared: bool = False
    status: str

    class Settings:
        name = "reservations"
