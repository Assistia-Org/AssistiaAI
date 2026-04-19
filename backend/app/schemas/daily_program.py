from datetime import date
from typing import List, Optional
from pydantic import BaseModel, Field
from app.schemas.base import BaseSchema

from app.schemas.task import TaskResponse
from app.schemas.reservation import ReservationResponse

class DailyProgramSummarySchema(BaseModel):
    """Schema for the program summary."""
    task_sayisi: int = 0
    etkinlik_sayisi: int = 0

    class Config:
        from_attributes = True

class DailyProgramItemsSchema(BaseModel):
    """Schema for the items collection in a daily program."""
    tasks: List[TaskResponse] = Field(default_factory=list, description="List of Task objects")
    etkinlikler: List[ReservationResponse] = Field(default_factory=list, description="List of Reservation objects")

    class Config:
        from_attributes = True

class DailyProgramBase(BaseModel):
    """Base schema for DailyProgram."""
    tarih: date
    kullanici_id: str
    ozet: DailyProgramSummarySchema = Field(default_factory=DailyProgramSummarySchema)
    items: DailyProgramItemsSchema = Field(default_factory=DailyProgramItemsSchema)

class DailyProgramCreate(DailyProgramBase):
    """Schema for creating a DailyProgram."""
    pass

class DailyProgramUpdate(BaseModel):
    """Schema for updating a DailyProgram."""
    tarih: Optional[date] = None
    items: Optional[DailyProgramItemsSchema] = None
    ozet: Optional[DailyProgramSummarySchema] = None

class DailyProgramResponse(DailyProgramBase, BaseSchema):
    """Response schema for DailyProgram."""
    id: str = Field(alias="_id")

    class Config:
        from_attributes = True
        populate_by_name = True

    @classmethod
    def model_validate(cls, obj, **kwargs):
        """Custom validation to handle ObjectId to string conversion."""
        if hasattr(obj, "id"):
            obj._id = str(obj.id)
        return super().model_validate(obj, **kwargs)
