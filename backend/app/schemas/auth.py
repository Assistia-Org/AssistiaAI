from typing import Optional
from pydantic import BaseModel, EmailStr

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str

class TokenPayload(BaseModel):
    sub: Optional[str] = None
    type: Optional[str] = None

class TokenRefresh(BaseModel):
    refresh_token: str

class LoginSchema(BaseModel):
    email: EmailStr
    password: str
