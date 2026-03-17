from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from beanie import PydanticObjectId
from app.models.integration import IntegrationService

class IntegrationBase(BaseModel):
    service: IntegrationService
    access_token: str
    refresh_token: Optional[str] = None
    expires_at: Optional[datetime] = None

class IntegrationCreate(IntegrationBase):
    user_id: PydanticObjectId

class IntegrationUpdate(BaseModel):
    access_token: Optional[str] = None
    refresh_token: Optional[str] = None
    expires_at: Optional[datetime] = None

class IntegrationOut(IntegrationBase):
    id: PydanticObjectId = Field(alias="_id")
    user_id: PydanticObjectId
    connected_at: datetime
    is_deleted: bool

    class Config:
        populate_by_name = True
