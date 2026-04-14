from pydantic import BaseModel, Field
from typing import List, Optional
from beanie import PydanticObjectId
from backend.app.models.user_preference import BudgetRange

class UserPreferenceBase(BaseModel):
    preferred_airlines: List[str] = Field(default_factory=list)
    preferred_hotels: List[str] = Field(default_factory=list)
    seat_preference: Optional[str] = None
    meeting_duration_default: Optional[int] = 30
    travel_budget_range: Optional[BudgetRange] = None
    dietary_preferences: List[str] = Field(default_factory=list)

class UserPreferenceCreate(UserPreferenceBase):
    user_id: PydanticObjectId

class UserPreferenceUpdate(BaseModel):
    preferred_airlines: Optional[List[str]] = None
    preferred_hotels: Optional[List[str]] = None
    seat_preference: Optional[str] = None
    meeting_duration_default: Optional[int] = None
    travel_budget_range: Optional[BudgetRange] = None
    dietary_preferences: Optional[List[str]] = None

class UserPreferenceOut(UserPreferenceBase):
    id: PydanticObjectId = Field(alias="_id")
    user_id: PydanticObjectId
    is_deleted: bool

    class Config:
        populate_by_name = True
