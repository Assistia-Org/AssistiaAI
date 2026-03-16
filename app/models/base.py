from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional

class SoftDeleteMixin(BaseModel):
    is_deleted: bool = Field(default=False)
    deleted_at: Optional[datetime] = Field(default=None)
