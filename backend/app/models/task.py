from typing import List, Optional
from datetime import datetime
from pydantic import Field
from app.models.base import BaseDocument

class Task(BaseDocument):
    id: str = Field(alias="_id")
    creator_id: str
    assigned_to: List[str] = Field(default_factory=list)
    community_id: Optional[str] = None
    title: str
    description: Optional[str] = None
    due_date: Optional[datetime] = None
    priority: str = "medium"
    status: str = "pending"
    tags: List[str] = Field(default_factory=list)

    class Settings:
        name = "tasks"
