from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from datetime import datetime
from beanie import PydanticObjectId

class CommandBase(BaseModel):
    raw_command: str
    intent: Optional[str] = None
    parameters: Dict[str, Any] = Field(default_factory=dict)
    confidence: Optional[float] = None

class CommandCreate(CommandBase):
    user_id: PydanticObjectId

class CommandUpdate(BaseModel):
    intent: Optional[str] = None
    parameters: Optional[Dict[str, Any]] = None
    confidence: Optional[float] = None

class CommandOut(CommandBase):
    id: PydanticObjectId = Field(alias="_id")
    user_id: PydanticObjectId
    timestamp: datetime
    is_deleted: bool

    class Config:
        populate_by_name = True
