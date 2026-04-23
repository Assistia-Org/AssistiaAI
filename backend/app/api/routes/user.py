from fastapi import APIRouter, status, Depends
from app.schemas.user import UserResponse, UserUpdate
from app.services.user_service import (
    delete_user_service,
    get_user_service,
    list_users_service,
    update_user_service,
    get_user_by_email_service,
)
from app.api.dependencies.auth import get_current_user
from app.models.user import User

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserResponse, status_code=status.HTTP_200_OK)
async def get_me(current_user: User = Depends(get_current_user)) -> UserResponse:
    """
    Get current authenticated user profile.
    """
    return UserResponse.model_validate(current_user)


@router.get("/{user_id}", response_model=UserResponse, status_code=status.HTTP_200_OK)
async def get_user(
    user_id: str, 
    current_user: User = Depends(get_current_user)
) -> UserResponse:
    """
    Kullanıcı detay getirme endpoint'i.
    Belirtilen ID'ye sahip kullanıcı bilgilerini döndürür.
    """
    return await get_user_service(user_id)


@router.get("/email/{email}", response_model=UserResponse, status_code=status.HTTP_200_OK)
async def get_user_by_email(
    email: str,
    current_user: User = Depends(get_current_user)
) -> UserResponse:
    """
    Email ile kullanıcı getirme endpoint'i.
    Belirtilen e-posta adresine sahip kullanıcı bilgilerini döndürür.
    """
    return await get_user_by_email_service(email)


@router.get("/", response_model=list[UserResponse], status_code=status.HTTP_200_OK)
async def list_users(
    current_user: User = Depends(get_current_user)
) -> list[UserResponse]:
    """
    Kullanıcı listeleme endpoint'i.
    Sistemdeki tüm kullanıcıları liste halinde döndürür.
    """
    return await list_users_service()


@router.patch("/{user_id}", response_model=UserResponse, status_code=status.HTTP_200_OK)
async def update_user(
    user_id: str, 
    data: UserUpdate, 
    current_user: User = Depends(get_current_user)
) -> UserResponse:
    """
    Kullanıcı güncelleme endpoint'i.
    Belirtilen kullanıcıya ait bilgileri (şifre, email vb.) günceller.
    """
    return await update_user_service(user_id, data)


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(
    user_id: str, 
    current_user: User = Depends(get_current_user)
) -> None:
    """
    Kullanıcı silme endpoint'i.
    Belirtilen ID'ye sahip kullanıcıyı sistemden siler.
    """
    await delete_user_service(user_id)
