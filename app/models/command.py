from beanie import Document, PydanticObjectId
from pydantic import Field
from typing import Optional, Dict, Any
from datetime import datetime
from .base import SoftDeleteMixin

class Command(Document, SoftDeleteMixin):
    user_id: PydanticObjectId
    raw_command: str
    intent: Optional[str] = None
    parameters: Dict[str, Any] = Field(default_factory=dict)
    confidence: Optional[float] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)

    class Settings:
        name = "commands"
