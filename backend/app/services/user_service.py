from fastapi import HTTPException
from passlib.context import CryptContext
from app.core.messages.error_message import USER_NOT_FOUND, DUPLICATE_EMAIL
from app.repositories.user import (
    create_user,
    delete_user,
    get_user_by_email,
    get_user_by_id,
    list_users,
    update_user,
)
from app.schemas.user import UserCreate, UserResponse, UserUpdate

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    """Hash a password."""
    return pwd_context.hash(password)

async def create_user_service(data: UserCreate) -> UserResponse:
    """Orchestrate user creation with duplicate check and hashing."""
    existing_user = await get_user_by_email(data.email)
    if existing_user:
        raise HTTPException(status_code=400, detail=DUPLICATE_EMAIL)
    
    user_data = data.model_dump()
    user_data["hashed_password"] = hash_password(user_data.pop("password", ""))
    
    user = await create_user(user_data)
    return UserResponse.model_validate(user)

async def get_user_service(user_id: str) -> UserResponse:
    """Orchestrate user retrieval."""
    user = await get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail=USER_NOT_FOUND)
    return UserResponse.model_validate(user)

async def list_users_service() -> list[UserResponse]:
    """Orchestrate user listing."""
    users = await list_users()
    return [UserResponse.model_validate(u) for u in users]

async def update_user_service(user_id: str, data: UserUpdate) -> UserResponse:
    """Orchestrate user update."""
    user = await get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail=USER_NOT_FOUND)
    
    if data.email:
        existing_user = await get_user_by_email(data.email)
        if existing_user and str(existing_user.id) != str(user.id):
            raise HTTPException(status_code=400, detail=DUPLICATE_EMAIL)
    
    update_data = data.model_dump(exclude_unset=True)
    if "password" in update_data:
        update_data["hashed_password"] = hash_password(update_data.pop("password"))
        
    updated_user = await update_user(user, update_data)
    return UserResponse.model_validate(updated_user)

async def delete_user_service(user_id: str) -> None:
    """Orchestrate user deletion."""
    user = await get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail=USER_NOT_FOUND)
    await delete_user(user)
