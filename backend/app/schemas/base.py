from datetime import datetime, timezone
from typing import Optional
from pydantic import BaseModel

class BaseSchema(BaseModel):
    created_at: datetime
    created_by: Optional[str] = None
    updated_at: Optional[datetime] = None
    updated_by: Optional[str] = None
    deleted_at: Optional[datetime] = None
    deleted_by: Optional[str] = None
    is_deleted: bool = False
