from beanie import Document, PydanticObjectId
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from .base import SoftDeleteMixin

class BudgetRange(BaseModel):
    min: float
    max: float

class UserPreference(Document, SoftDeleteMixin):
    user_id: PydanticObjectId
    preferred_airlines: List[str] = Field(default_factory=list)
    preferred_hotels: List[str] = Field(default_factory=list)
    seat_preference: Optional[str] = None
    meeting_duration_default: Optional[int] = 30
    travel_budget_range: Optional[BudgetRange] = None
    dietary_preferences: List[str] = Field(default_factory=list)

    class Settings:
        name = "user_preferences"
