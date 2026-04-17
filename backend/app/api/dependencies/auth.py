from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from pydantic import ValidationError

from app.core.config import settings
from app.core.messages.error_message import (
    COULD_NOT_VALIDATE_CREDENTIALS,
    USER_NOT_FOUND,
    INACTIVE_USER
)
from app.repositories.user import get_user_by_id
from app.schemas.auth import TokenPayload
from app.models.user import User

reusable_oauth2 = OAuth2PasswordBearer(
    tokenUrl="/api/v1/auth/login/swagger"
)


async def get_current_user(
    token: str = Depends(reusable_oauth2)
) -> User:
    """Validate and return the current user based on JWT token."""
    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        token_data = TokenPayload(**payload)
    except (JWTError, ValidationError):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=COULD_NOT_VALIDATE_CREDENTIALS,
        )
    
    user = await get_user_by_id(token_data.sub)
    if not user:
        raise HTTPException(status_code=404, detail=USER_NOT_FOUND)
    
    if not user.is_active:
        raise HTTPException(status_code=400, detail=INACTIVE_USER)
        
    return user
