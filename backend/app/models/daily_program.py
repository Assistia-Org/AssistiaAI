from datetime import date
from typing import List
from pydantic import BaseModel
from beanie import Link
from app.models.base import BaseDocument
from app.models.task import Task
from app.models.reservation import Reservation

class DailyProgramSummary(BaseModel):
    """Summary of task and event counts."""
    task_sayisi: int = 0
    etkinlik_sayisi: int = 0

class DailyProgramItems(BaseModel):
    """Container for tasks and events in a daily program."""
    tasks: List[Link[Task]] = []
    etkinlikler: List[Link[Reservation]] = []

class DailyProgram(BaseDocument):
    """Daily Program model representing a user's schedule for a specific date."""
    tarih: date
    kullanici_id: str
    ozet: DailyProgramSummary
    items: DailyProgramItems

    class Settings:
        name = "daily_programs"
