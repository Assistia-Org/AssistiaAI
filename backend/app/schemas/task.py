from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel

class TaskBase(BaseModel):
    creator_id: str
    assigned_to: List[str] = []
    community_id: Optional[str] = None
    title: str
    description: Optional[str] = None
    due_date: Optional[datetime] = None
    priority: str = "medium"
    status: str = "pending"
    tags: List[str] = []

class TaskCreate(TaskBase):
    id: str

class TaskUpdate(BaseModel):
    assigned_to: Optional[List[str]] = None
    title: Optional[str] = None
    description: Optional[str] = None
    due_date: Optional[datetime] = None
    priority: Optional[str] = None
    status: Optional[str] = None
    tags: Optional[List[str]] = None

class TaskResponse(TaskBase):
    id: str

    class Config:
        from_attributes = True
        populate_by_name = True
