from fastapi import APIRouter, status
from backend.app.schemas.user_preference import UserPreferenceCreate, UserPreferenceOut, UserPreferenceUpdate
from backend.app.services.user_preference_service import (
    create_user_preference_service,
    delete_user_preference_service,
    get_user_preference_by_user_service,
    get_user_preference_service,
    list_user_preferences_service,
    update_user_preference_service,
)

router = APIRouter(prefix="/user-preferences", tags=["user_preferences"])


@router.post("/", response_model=UserPreferenceOut, status_code=status.HTTP_201_CREATED)
async def create_user_preference(data: UserPreferenceCreate) -> UserPreferenceOut:
    """
    Kullanıcı tercihleri oluşturma endpoint'i.
    Havayolu, beslenme tipi veya koltuk seçimleri gibi ilk profil ayarlarını kaydeder.
    """
    return await create_user_preference_service(data)


@router.get("/{preference_id}", response_model=UserPreferenceOut, status_code=status.HTTP_200_OK)
async def get_user_preference(preference_id: str) -> UserPreferenceOut:
    """
    Tercihleri ID bazlı çağırma endpoint'i.
    Kayıtlı veri kümesine ait referans numarası üzerinden tercihleri listeletir.
    """
    return await get_user_preference_service(preference_id)


@router.get("/user/{user_id}", response_model=UserPreferenceOut, status_code=status.HTTP_200_OK)
async def get_user_preference_by_user(user_id: str) -> UserPreferenceOut:
    """
    Kullanıcıya ait spesifik tercih getirme endpoint'i.
    Belli bir kullanıcının seyahat veya asistan kullanım (meeting duration) ayarlarını döner.
    """
    return await get_user_preference_by_user_service(user_id)


@router.get("/", response_model=list[UserPreferenceOut], status_code=status.HTTP_200_OK)
async def list_user_preferences() -> list[UserPreferenceOut]:
    """
    Sistemdeki tüm tercih tanımlamalarını listeleme endpoint'i.
    """
    return await list_user_preferences_service()


@router.patch("/user/{user_id}", response_model=UserPreferenceOut, status_code=status.HTTP_200_OK)
async def update_user_preference(user_id: str, data: UserPreferenceUpdate) -> UserPreferenceOut:
    """
    Tercih güncelleme endpoint'i.
    Diyet, koltuk (seat preference) veya havayolu değiştirildiğinde bu fonksiyonla kaydedilir.
    """
    return await update_user_preference_service(user_id, data)


@router.delete("/user/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user_preference(user_id: str) -> None:
    """
    Tercih silme endpoint'i.
    Kullanıcının özelleştirilmiş ayarlarını resetleyerek tamamen siler.
    """
    await delete_user_preference_service(user_id)
