from fastapi import APIRouter, status
from app.schemas.user import UserCreate, UserResponse, UserUpdate
from app.services.user_service import (
    create_user_service,
    delete_user_service,
    get_user_service,
    list_users_service,
    update_user_service,
)

router = APIRouter(prefix="/users", tags=["users"])


@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(data: UserCreate) -> UserResponse:
    """Create a new user."""
    return await create_user_service(data)


@router.get("/{user_id}", response_model=UserResponse, status_code=status.HTTP_200_OK)
async def get_user(user_id: str) -> UserResponse:
    """Get a user by ID."""
    return await get_user_service(user_id)


@router.get("/", response_model=list[UserResponse], status_code=status.HTTP_200_OK)
async def list_users() -> list[UserResponse]:
    """List all users."""
    return await list_users_service()


@router.patch("/{user_id}", response_model=UserResponse, status_code=status.HTTP_200_OK)
async def update_user(user_id: str, data: UserUpdate) -> UserResponse:
    """Update user details."""
    return await update_user_service(user_id, data)


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(user_id: str) -> None:
    """Delete a user."""
    await delete_user_service(user_id)
