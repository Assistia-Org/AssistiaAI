from fastapi import APIRouter, status
from app.schemas.verification import VerificationRequest, VerificationCheck
from app.services.verification_service import (
    request_verification_service,
    verify_code_service
)

router = APIRouter(prefix="/verification", tags=["verification"])

@router.post("/request", response_model=str, status_code=status.HTTP_200_OK)
async def request_verification(data: VerificationRequest) -> str:
    """Request a verification code to be sent to email."""
    return await request_verification_service(data.email)

@router.post("/verify", response_model=str, status_code=status.HTTP_200_OK)
async def verify_code(data: VerificationCheck) -> str:
    """Verify the code sent to email."""
    return await verify_code_service(data.email, data.code)
