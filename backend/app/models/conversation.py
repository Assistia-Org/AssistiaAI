from beanie import Document, PydanticObjectId
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from .base import SoftDeleteMixin

class Message(BaseModel):
    role: str
    text: str

class Conversation(Document, SoftDeleteMixin):
    user_id: PydanticObjectId
    messages: List[Message] = Field(default_factory=list)
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    intent: Optional[str] = None

    class Settings:
        name = "conversations"
