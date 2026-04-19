from fastapi import APIRouter, status, Depends, UploadFile, File
from app.schemas.reservation import ReservationCreate, ReservationResponse, ReservationUpdate
from app.services.ai_service import analyze_ticket_with_gemini, analyze_bus_ticket_with_gemini
from app.services.reservation_service import (
    create_reservation_service,
    delete_reservation_service,
    get_reservation_service,
    list_reservations_by_trip_service,
    list_reservations_by_user_service,
    update_reservation_service,
)
from app.api.dependencies.auth import get_current_user
from app.models.user import User

router = APIRouter(prefix="/reservations", tags=["reservations"])


@router.post("/", response_model=ReservationResponse, status_code=status.HTTP_201_CREATED)
async def create_reservation(
    data: ReservationCreate, 
    current_user: User = Depends(get_current_user)
) -> ReservationResponse:
    """
    Rezervasyon oluşturma endpoint'i.
    Yeni bir uçuş, otel veya araç kiralama rezervasyonunu detaylarıyla kaydeder.
    """
    return await create_reservation_service(str(current_user.id), data)


@router.post("/analyze", status_code=status.HTTP_200_OK)
async def analyze_reservation_ticket(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """
    Bilet analizi endpoint'i.
    Yüklenen bilet görselini veya PDF'ini AI ile analiz eder ve JSON döner.
    """
    content = await file.read()
    result = await analyze_ticket_with_gemini(content, file.content_type)
    return result

@router.post("/analyze-bus", status_code=status.HTTP_200_OK)
async def analyze_bus_ticket(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """
    Otobüs bileti analizi endpoint'i.
    Yüklenen bilet görselini veya PDF'ini AI ile analiz eder ve JSON döner.
    """
    content = await file.read()
    result = await analyze_bus_ticket_with_gemini(content, file.content_type)
    return result


@router.get("/{reservation_id}", response_model=ReservationResponse, status_code=status.HTTP_200_OK)
async def get_reservation(
    reservation_id: str, 
    current_user: User = Depends(get_current_user)
) -> ReservationResponse:
    """
    Rezervasyon detay getirme endpoint'i.
    Belirtilen ID'ye sahip spesifik rezervasyon pnr vb. verilerini döndürür.
    """
    return await get_reservation_service(reservation_id)


@router.get("/user/{user_id}", response_model=list[ReservationResponse], status_code=status.HTTP_200_OK)
async def list_user_reservations(
    user_id: str, 
    current_user: User = Depends(get_current_user)
) -> list[ReservationResponse]:
    """
    Kullanıcı rezervasyonlarını listeleme endpoint'i.
    Belirli bir kullanıcıya ait (farklı seyahatler dahil) tüm rezervasyonları getirir.
    """
    return await list_reservations_by_user_service(user_id)


@router.get("/trip/{trip_id}", response_model=list[ReservationResponse], status_code=status.HTTP_200_OK)
async def list_trip_reservations(
    trip_id: str, 
    current_user: User = Depends(get_current_user)
) -> list[ReservationResponse]:
    """
    Seyahat rezervasyonlarını listeleme endpoint'i.
    Spesifik bir gezi/seyahat altındaki (otel, uçak) tüm rezervasyonları küme olarak döner.
    """
    return await list_reservations_by_trip_service(trip_id)

@router.patch("/{reservation_id}", response_model=ReservationResponse, status_code=status.HTTP_200_OK)
async def update_reservation(
    reservation_id: str, 
    data: ReservationUpdate, 
    current_user: User = Depends(get_current_user)
) -> ReservationResponse:
    """
    Rezervasyon güncelleme endpoint'i.
    Mevcut rezervasyonun tarihlerini, sağlayıcı bilgisini (provider) veya ekstra bilgilerini düzenler.
    """
    return await update_reservation_service(reservation_id, data)


@router.delete("/{reservation_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_reservation(
    reservation_id: str, 
    current_user: User = Depends(get_current_user)
) -> None:
    """
    Rezervasyon silme endpoint'i.
    İptal edilen rezervasyon girişini veritabanından kalıcı olarak kaldırır.
    """
    await delete_reservation_service(reservation_id)
