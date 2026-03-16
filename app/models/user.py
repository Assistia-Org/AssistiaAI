from beanie import Document, Indexed
from pydantic import EmailStr, Field
from datetime import datetime
from typing import Optional
from .base import SoftDeleteMixin

class User(Document, SoftDeleteMixin):
    full_name: str
    email: Indexed(EmailStr, unique=True)
    password_hash: str
    timezone: Optional[str] = "Europe/Istanbul"
    language: Optional[str] = "Turkish"
    created_at: datetime = Field(default_factory=datetime.utcnow)
    subscription_plan: Optional[str] = "Free"

    class Settings:
        name = "users"
