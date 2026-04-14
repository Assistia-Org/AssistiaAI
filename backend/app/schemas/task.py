from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from beanie import PydanticObjectId
from backend.app.models.task import TaskStatus, TaskPriority

class TaskBase(BaseModel):
    title: str
    description: Optional[str] = None
    due_date: Optional[datetime] = None
    status: TaskStatus = TaskStatus.pending
    priority: TaskPriority = TaskPriority.medium

class TaskCreate(TaskBase):
    user_id: PydanticObjectId

class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    due_date: Optional[datetime] = None
    status: Optional[TaskStatus] = None
    priority: Optional[TaskPriority] = None

class TaskOut(TaskBase):
    id: PydanticObjectId = Field(alias="_id")
    user_id: PydanticObjectId
    is_deleted: bool

    class Config:
        populate_by_name = True
