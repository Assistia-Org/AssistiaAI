from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel
from app.schemas.base import BaseSchema
from app.models.task import TaskStatus

class TaskBase(BaseModel):
    creator_id: str
    assigned_to: List[str] = []
    community_id: Optional[str] = None
    type: str = "Görev"
    title: str
    description: Optional[str] = None
    due_date: Optional[datetime] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    priority: str = "medium"
    status: TaskStatus = TaskStatus.PENDING
    tags: List[str] = []

class TaskCreate(TaskBase):
    pass

class TaskUpdate(BaseModel):
    assigned_to: Optional[List[str]] = None
    title: Optional[str] = None
    description: Optional[str] = None
    due_date: Optional[datetime] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    priority: Optional[str] = None
    status: Optional[TaskStatus] = None
    tags: Optional[List[str]] = None

class TaskResponse(TaskBase, BaseSchema):
    id: str

    class Config:
        from_attributes = True
        populate_by_name = True
