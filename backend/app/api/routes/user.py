from fastapi import APIRouter, status
from backend.app.schemas.user import UserCreate, UserOut, UserUpdate
from backend.app.services.user_service import (
    create_user_service,
    delete_user_service,
    get_user_service,
    list_users_service,
    update_user_service,
)

router = APIRouter(prefix="/users", tags=["users"])


@router.post("/", response_model=UserOut, status_code=status.HTTP_201_CREATED)
async def create_user(data: UserCreate) -> UserOut:
    """
    Kullanıcı oluşturma endpoint'i.
    Gelen verilerle yeni bir kullanıcı hesabı açar.
    """
    return await create_user_service(data)


@router.get("/{user_id}", response_model=UserOut, status_code=status.HTTP_200_OK)
async def get_user(user_id: str) -> UserOut:
    """
    Kullanıcı detay getirme endpoint'i.
    Belirtilen ID'ye sahip kullanıcı bilgilerini döndürür.
    """
    return await get_user_service(user_id)


@router.get("/", response_model=list[UserOut], status_code=status.HTTP_200_OK)
async def list_users() -> list[UserOut]:
    """
    Kullanıcı listeleme endpoint'i.
    Sistemdeki tüm kullanıcıları liste halinde döndürür.
    """
    return await list_users_service()


@router.patch("/{user_id}", response_model=UserOut, status_code=status.HTTP_200_OK)
async def update_user(user_id: str, data: UserUpdate) -> UserOut:
    """
    Kullanıcı güncelleme endpoint'i.
    Belirtilen kullanıcıya ait bilgileri (şifre, email vb.) günceller.
    """
    return await update_user_service(user_id, data)


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(user_id: str) -> None:
    """
    Kullanıcı silme endpoint'i.
    Belirtilen ID'ye sahip kullanıcıyı sistemden siler.
    """
    await delete_user_service(user_id)
