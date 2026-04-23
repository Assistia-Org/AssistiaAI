from typing import List, Optional
from datetime import datetime
from pydantic import Field
from enum import Enum
from app.models.base import BaseDocument
from uuid import uuid4

class TaskStatus(str, Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
class Task(BaseDocument):
    id: str = Field(default_factory=lambda: uuid4().hex, alias="_id")
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
