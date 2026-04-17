from fastapi import HTTPException, status
from jose import jwt, JWTError
from pydantic import ValidationError
from app.core.config import settings
from app.core.security import get_password_hash, verify_password, create_access_token, create_refresh_token
from app.repositories.user import create_user, get_user_by_email, get_user_by_id
from app.schemas.auth import LoginSchema, Token, TokenPayload, TokenRefresh
from app.schemas.user import UserCreate, UserResponse
from app.core.messages.error_message import (
    DUPLICATE_EMAIL, 
    INCORRECT_EMAIL_OR_PASSWORD, 
    INVALID_REFRESH_TOKEN,
    USER_NOT_FOUND
)

async def register_user_service(data: UserCreate) -> UserResponse:
    """
    Handle user registration.
    Checks for duplicate email and hashes password before storage.
    """
    existing_user = await get_user_by_email(data.email)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail=DUPLICATE_EMAIL
        )
    
    user_data = data.model_dump()
    # Replace plain password with hashed version
    user_data["hashed_password"] = get_password_hash(user_data.pop("password"))
    
    user = await create_user(user_data)
    return UserResponse.model_validate(user)

async def login_service(data: LoginSchema) -> Token:
    """
    Handle user login.
    Verifies credentials and returns access and refresh JWT tokens.
    """
    user = await get_user_by_email(data.email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=INCORRECT_EMAIL_OR_PASSWORD
        )
    
    if not verify_password(data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=INCORRECT_EMAIL_OR_PASSWORD
        )
        
    access_token = create_access_token(subject=user.id)
    refresh_token = create_refresh_token(subject=user.id)
    return Token(
        access_token=access_token, 
        refresh_token=refresh_token, 
        token_type="bearer"
    )

async def refresh_token_service(data: TokenRefresh) -> Token:
    """
    Refresh access and refresh tokens using a valid refresh token.
    Implements token rotation for sliding session.
    """
    try:
        payload = jwt.decode(
            data.refresh_token, 
            settings.SECRET_KEY, 
            algorithms=[settings.ALGORITHM]
        )
        token_data = TokenPayload(**payload)
        if token_data.type != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=INVALID_REFRESH_TOKEN
            )
    except (JWTError, ValidationError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=INVALID_REFRESH_TOKEN
        )
    
    user = await get_user_by_id(token_data.sub)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=USER_NOT_FOUND
        )
        
    new_access_token = create_access_token(subject=user.id)
    new_refresh_token = create_refresh_token(subject=user.id)
    
    return Token(
        access_token=new_access_token,
        refresh_token=new_refresh_token,
        token_type="bearer"
    )
