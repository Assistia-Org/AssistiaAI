from datetime import datetime
from fastapi import APIRouter, status
from app.models.integration import IntegrationService
from app.schemas.integration import IntegrationCreate, IntegrationOut, IntegrationUpdate
from app.services.integration_service import (
    create_integration_service,
    delete_integration_service,
    get_integration_service,
    list_integrations_by_user_service,
    get_user_service_integration_service,
    update_integration_service,
    update_tokens_service,
)

router = APIRouter(prefix="/integrations", tags=["integrations"])


@router.post("/", response_model=IntegrationOut, status_code=status.HTTP_201_CREATED)
async def create_integration(data: IntegrationCreate) -> IntegrationOut:
    """
    Entegrasyon oluşturma endpoint'i.
    Kullanıcıya ait yeni bir harici servis (Google Calendar vb.) entegrasyonu ekler.
    """
    return await create_integration_service(data)


@router.get("/{integration_id}", response_model=IntegrationOut, status_code=status.HTTP_200_OK)
async def get_integration(integration_id: str) -> IntegrationOut:
    """
    Entegrasyon detay getirme endpoint'i.
    Belirtilen entegrasyonun erişim durumunu ve token tarihlerini döndürür.
    """
    return await get_integration_service(integration_id)


@router.get("/user/{user_id}", response_model=list[IntegrationOut], status_code=status.HTTP_200_OK)
async def list_user_integrations(user_id: str) -> list[IntegrationOut]:
    """
    Kullanıcı entegrasyonlarını listeleme endpoint'i.
    Kullanıcının sisteme bağlı tüm servislerini (ör. Calendar, Mail) listeler.
    """
    return await list_integrations_by_user_service(user_id)


@router.get("/user/{user_id}/{service}", response_model=IntegrationOut, status_code=status.HTTP_200_OK)
async def get_user_service_integration(user_id: str, service: IntegrationService) -> IntegrationOut:
    """
    Servis tabanlı entegrasyon getirme endpoint'i.
    Özel bir servisin (ör. Google) kullanıcının hesabındaki bağlantı detayını getirir.
    """
    return await get_user_service_integration_service(user_id, service)


@router.patch("/{integration_id}", response_model=IntegrationOut, status_code=status.HTTP_200_OK)
async def update_integration(integration_id: str, data: IntegrationUpdate) -> IntegrationOut:
    """
    Entegrasyon güncelleme endpoint'i.
    Belirtilen entegrasyon verilerini günceller.
    """
    return await update_integration_service(integration_id, data)


@router.patch("/{integration_id}/tokens", response_model=IntegrationOut, status_code=status.HTTP_200_OK)
async def update_integration_tokens(
    integration_id: str, 
    access_token: str, 
    refresh_token: str | None = None, 
    expires_at: datetime | None = None
) -> IntegrationOut:
    """
    Entegrasyon token güncelleme endpoint'i.
    Süresi dolan entegrasyon tokenlarını yenilemek (refresh) için kullanılır.
    """
    return await update_tokens_service(integration_id, access_token, refresh_token, expires_at)


@router.delete("/{integration_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_integration(integration_id: str) -> None:
    """
    Entegrasyon silme endpoint'i.
    Kullanıcının servise olan bağlantısını kaldırır.
    """
    await delete_integration_service(integration_id)
