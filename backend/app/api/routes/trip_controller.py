from fastapi import APIRouter, status
from backend.app.schemas.trip import TripCreate, TripOut, TripUpdate
from backend.app.services.trip_service import (
    create_trip_service,
    delete_trip_service,
    get_trip_service,
    list_all_trips_service,
    list_trips_by_user_service,
    update_trip_service,
)

router = APIRouter(prefix="/trips", tags=["trips"])


@router.post("/", response_model=TripOut, status_code=status.HTTP_201_CREATED)
async def create_trip(data: TripCreate) -> TripOut:
    """
    Seyahat planı oluşturma endpoint'i.
    Yeni bir iş gezisi (trip) için taslak ekler, tarih ve lokasyon alır.
    """
    return await create_trip_service(data)


@router.get("/{trip_id}", response_model=TripOut, status_code=status.HTTP_200_OK)
async def get_trip(trip_id: str) -> TripOut:
    """
    Seyahat detay getirme endpoint'i.
    Özel bir seyahat turunun varış konumu ile notlarını okumak için kullanılır.
    """
    return await get_trip_service(trip_id)


@router.get("/user/{user_id}", response_model=list[TripOut], status_code=status.HTTP_200_OK)
async def list_user_trips(user_id: str) -> list[TripOut]:
    """
    Kullanıcı seyahatlerini listeleme endpoint'i.
    Kullanıcının geçmişteki ve gelecekteki turlarını/gezilerini döner.
    """
    return await list_trips_by_user_service(user_id)


@router.get("/", response_model=list[TripOut], status_code=status.HTTP_200_OK)
async def list_all_trips() -> list[TripOut]:
    """
    Tüm çalışan/kullanıcı seyahatlerini sistem genelinde listeleme endpoint'i.
    Raporlama için toplu veri sağlar.
    """
    return await list_all_trips_service()


@router.patch("/{trip_id}", response_model=TripOut, status_code=status.HTTP_200_OK)
async def update_trip(trip_id: str, data: TripUpdate) -> TripOut:
    """
    Seyahat planı güncelleme endpoint'i.
    Tarih değişiklikleri, erteleme ya da seyahat rotasındaki güncellemeler içindir.
    """
    return await update_trip_service(trip_id, data)


@router.delete("/{trip_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_trip(trip_id: str) -> None:
    """
    Seyahat silme endpoint'i.
    İptal edilen genel seyahati bütünüyle listeden alır.
    """
    await delete_trip_service(trip_id)
