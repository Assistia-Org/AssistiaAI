import re
from fastapi import HTTPException, status
from app.core.messages.error_message import INVALID_PASSWORD_STRUCTURE

def validate_password_strength(password: str) -> str:
    """
    Validate password strength:
    - Greater than 6 characters
    - Only letters (A-Z, a-z), numbers (0-9), underscores (_), and dots (.)
    """
    if len(password) <= 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=INVALID_PASSWORD_STRUCTURE
        )
    
    # Check for allowed characters only
    if not re.match(r'^[a-zA-Z0-9_.]+$', password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=INVALID_PASSWORD_STRUCTURE
        )
    
    return password
