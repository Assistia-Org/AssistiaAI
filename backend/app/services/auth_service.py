from fastapi import HTTPException, status
from app.core.security import get_password_hash, verify_password, create_access_token
from app.repositories.user import create_user, get_user_by_email
from app.schemas.auth import LoginSchema, Token
from app.schemas.user import UserCreate, UserResponse
from app.core.messages.error_message import DUPLICATE_EMAIL, INCORRECT_EMAIL_OR_PASSWORD

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
    Verifies credentials and returns a JWT token.
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
    return Token(access_token=access_token, token_type="bearer")
