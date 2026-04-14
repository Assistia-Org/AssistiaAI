from fastapi import APIRouter, status
from backend.app.schemas.reservation import ReservationCreate, ReservationOut, ReservationUpdate
from backend.app.services.reservation_service import (
    create_reservation_service,
    delete_reservation_service,
    get_reservation_service,
    list_reservations_by_trip_service,
    list_reservations_by_user_service,
    update_reservation_service,
)

router = APIRouter(prefix="/reservations", tags=["reservations"])


@router.post("/", response_model=ReservationOut, status_code=status.HTTP_201_CREATED)
async def create_reservation(data: ReservationCreate) -> ReservationOut:
    """
    Rezervasyon oluşturma endpoint'i.
    Yeni bir uçuş, otel veya araç kiralama rezervasyonunu detaylarıyla kaydeder.
    """
    return await create_reservation_service(data)


@router.get("/{reservation_id}", response_model=ReservationOut, status_code=status.HTTP_200_OK)
async def get_reservation(reservation_id: str) -> ReservationOut:
    """
    Rezervasyon detay getirme endpoint'i.
    Belirtilen ID'ye sahip spesifik rezervasyon pnr vb. verilerini döndürür.
    """
    return await get_reservation_service(reservation_id)


@router.get("/user/{user_id}", response_model=list[ReservationOut], status_code=status.HTTP_200_OK)
async def list_user_reservations(user_id: str) -> list[ReservationOut]:
    """
    Kullanıcı rezervasyonlarını listeleme endpoint'i.
    Belirli bir kullanıcıya ait (farklı seyahatler dahil) tüm rezervasyonları getirir.
    """
    return await list_reservations_by_user_service(user_id)


@router.get("/trip/{trip_id}", response_model=list[ReservationOut], status_code=status.HTTP_200_OK)
async def list_trip_reservations(trip_id: str) -> list[ReservationOut]:
    """
    Seyahat rezervasyonlarını listeleme endpoint'i.
    Spesifik bir gezi/seyahat altındaki (otel, uçak) tüm rezervasyonları küme olarak döner.
    """
    return await list_reservations_by_trip_service(trip_id)


@router.patch("/{reservation_id}", response_model=ReservationOut, status_code=status.HTTP_200_OK)
async def update_reservation(reservation_id: str, data: ReservationUpdate) -> ReservationOut:
    """
    Rezervasyon güncelleme endpoint'i.
    Mevcut rezervasyonun tarihlerini, sağlayıcı bilgisini (provider) veya ekstra bilgilerini düzenler.
    """
    return await update_reservation_service(reservation_id, data)


@router.delete("/{reservation_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_reservation(reservation_id: str) -> None:
    """
    Rezervasyon silme endpoint'i.
    İptal edilen rezervasyon girişini veritabanından kalıcı olarak kaldırır.
    """
    await delete_reservation_service(reservation_id)
