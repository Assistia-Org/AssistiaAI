from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from beanie import PydanticObjectId
from backend.app.models.conversation import Message

class ConversationBase(BaseModel):
    intent: Optional[str] = None
    messages: List[Message] = Field(default_factory=list)

class ConversationCreate(ConversationBase):
    user_id: PydanticObjectId

class ConversationUpdate(BaseModel):
    intent: Optional[str] = None
    messages: Optional[List[Message]] = None

class ConversationOut(ConversationBase):
    id: PydanticObjectId = Field(alias="_id")
    user_id: PydanticObjectId
    timestamp: datetime
    is_deleted: bool

    class Config:
        populate_by_name = True
