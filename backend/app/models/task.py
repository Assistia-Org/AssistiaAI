from typing import List, Optional
from datetime import datetime
from enum import Enum
from pydantic import Field
from app.models.base import BaseDocument

class TaskStatus(str, Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class Task(BaseDocument):
    id: str = Field(alias="_id")
    creator_id: str
    assigned_to: List[str] = Field(default_factory=list)
    community_id: Optional[str] = None
    type: str = "Görev"
    title: str
    description: Optional[str] = None
    due_date: Optional[datetime] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    priority: str = "medium"
    status: TaskStatus = TaskStatus.PENDING
    tags: List[str] = Field(default_factory=list)

    class Settings:
        name = "tasks"