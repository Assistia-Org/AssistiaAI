from beanie import Document, Indexed
from pydantic import EmailStr, Field
from datetime import datetime

class User(Document):
    """Beanie model for a User."""
    full_name: str
    email: Indexed(EmailStr, unique=True)
    hashed_password: str
    is_active: bool = True
    is_superuser: bool = False
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Settings:
        name = "users"
