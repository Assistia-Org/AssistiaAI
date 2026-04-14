from beanie import Document, PydanticObjectId
from pydantic import Field
from typing import Optional
from datetime import datetime
from enum import Enum
from .base import SoftDeleteMixin

class TaskStatus(str, Enum):
    pending = "pending" # değişecek
    in_progress = "in_progress" # değişecek
    completed = "completed"

class TaskPriority(str, Enum):
    low = "low"
    medium = "medium"
    high = "high"
    urgent = "urgent"

class Task(Document, SoftDeleteMixin):
    user_id: PydanticObjectId # değişecek
    title: str
    description: Optional[str] = None
    due_date: Optional[datetime] = None
    status: TaskStatus = TaskStatus.pending
    priority: TaskPriority = TaskPriority.medium

    class Settings:
        name = "tasks"
