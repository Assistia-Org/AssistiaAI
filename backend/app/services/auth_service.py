import secrets
from datetime import datetime, timedelta, timezone
from fastapi import HTTPException, status
from jose import jwt, JWTError
from pydantic import ValidationError
from app.core.config import settings
from app.core.security import get_password_hash, verify_password, create_access_token, create_refresh_token
from app.repositories.user import (
    create_user, 
    get_user_by_email, 
    get_user_by_id, 
    get_user_by_reset_token
)
from app.models.user import User
from app.schemas.auth import (
    LoginSchema, 
    Token, 
    TokenPayload, 
    TokenRefresh, 
    ForgotPasswordRequest, 
    ResetPasswordRequest,
    ChangePasswordRequest
)
from app.schemas.user import UserCreate, UserResponse
from app.core.messages.error_message import (
    DUPLICATE_EMAIL, 
    INCORRECT_EMAIL_OR_PASSWORD, 
    INVALID_REFRESH_TOKEN,
    USER_NOT_FOUND,
    INVALID_OR_EXPIRED_TOKEN,
    EMAIL_SEND_FAILED,
    INCORRECT_CURRENT_PASSWORD,
    INVALID_PASSWORD_STRUCTURE
)
from app.core.messages.success_message import (
    PASSWORD_RESET_EMAIL_SENT,
    PASSWORD_RESET_SUCCESS,
    PASSWORD_CHANGED
)
from app.utils.email import send_password_reset_email
from app.utils.validators import validate_password_strength

async def change_password_service(user: User, data: ChangePasswordRequest) -> dict:
    """
    Change user password after verifying the current one.
    """
    if not verify_password(data.current_password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=INCORRECT_CURRENT_PASSWORD
        )
    
    if data.new_password != data.confirm_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Passwords do not match."
        )
    
    # Validate password strength
    validate_password_strength(data.new_password)
    
    user.hashed_password = get_password_hash(data.new_password)
    await user.save()
    
    return {"message": PASSWORD_CHANGED}

async def forgot_password_service(data: ForgotPasswordRequest) -> dict:
    """
    Generate a reset token, save to user document, and send email.
    """
    user = await get_user_by_email(data.email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=USER_NOT_FOUND
        )
    
    token = secrets.token_urlsafe(32)
    user.reset_token = token
    user.reset_token_expires_at = datetime.now(timezone.utc) + timedelta(hours=1)
    await user.save()
    
    email_sent = send_password_reset_email(user.email, token)
    if not email_sent:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=EMAIL_SEND_FAILED
        )
    
    return {"message": PASSWORD_RESET_EMAIL_SENT}

async def reset_password_service(data: ResetPasswordRequest) -> dict:
    """
    Reset user password using the provided token.
    """
    if data.new_password != data.confirm_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Passwords do not match."
        )
    
    # Validate password strength
    validate_password_strength(data.new_password)
    
    user = await get_user_by_reset_token(data.token)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=INVALID_OR_EXPIRED_TOKEN
        )
    
    # Check expiry
    if user.reset_token_expires_at.replace(tzinfo=timezone.utc) < datetime.now(timezone.utc):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=INVALID_OR_EXPIRED_TOKEN
        )
    
    # Update password and clear token
    user.hashed_password = get_password_hash(data.new_password)
    user.reset_token = None
    user.reset_token_expires_at = None
    await user.save()
    
    return {"message": PASSWORD_RESET_SUCCESS}

async def register_user_service(data: UserCreate) -> UserResponse:
    """
    Handle user registration.
    Checks for duplicate email and hashes password before storage.
    """
    # Validate password strength
    validate_password_strength(data.password)
    
    existing_user = await get_user_by_email(data.email)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail=DUPLICATE_EMAIL
        )
    
    user_data = data.model_dump(exclude_none=True)
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
