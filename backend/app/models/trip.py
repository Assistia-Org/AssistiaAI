from beanie import Document, PydanticObjectId
from pydantic import Field
from typing import Optional
from datetime import datetime
from .base import SoftDeleteMixin

class Trip(Document, SoftDeleteMixin):
    user_id: PydanticObjectId
    title: str
    destination: str
    start_date: datetime
    end_date: datetime
    status: str = "planned"
    notes: Optional[str] = None

    class Settings:
        name = "trips"
