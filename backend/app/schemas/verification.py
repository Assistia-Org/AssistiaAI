from pydantic import BaseModel, EmailStr

class VerificationRequest(BaseModel):
    email: EmailStr

class VerificationCheck(BaseModel):
    email: EmailStr
    code: str
