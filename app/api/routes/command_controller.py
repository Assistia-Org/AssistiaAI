from fastapi import APIRouter, status
from app.schemas.command import CommandCreate, CommandOut, CommandUpdate
from app.services.command_service import (
    create_command_service,
    delete_command_service,
    get_command_service,
    list_commands_by_user_service,
    update_command_service,
    update_command_intent_service,
    update_command_parameters_service,
)

router = APIRouter(prefix="/commands", tags=["commands"])


@router.post("/", response_model=CommandOut, status_code=status.HTTP_201_CREATED)
async def create_command(data: CommandCreate) -> CommandOut:
    """
    Komut oluşturma endpoint'i.
    Kullanıcının gönderdiği ham (raw) komutu sisteme kaydeder.
    """
    return await create_command_service(data)


@router.get("/{command_id}", response_model=CommandOut, status_code=status.HTTP_200_OK)
async def get_command(command_id: str) -> CommandOut:
    """
    Komut detay getirme endpoint'i.
    Belirtilen ID'ye sahip komutun detaylarını ve parametrelerini getirir.
    """
    return await get_command_service(command_id)


@router.get("/user/{user_id}", response_model=list[CommandOut], status_code=status.HTTP_200_OK)
async def list_user_commands(user_id: str) -> list[CommandOut]:
    """
    Kullanıcı komutlarını listeleme endpoint'i.
    Belirtilen kullanıcıya ait olan tüm komut geçmişini liste halinde döndürür.
    """
    return await list_commands_by_user_service(user_id)


@router.patch("/{command_id}", response_model=CommandOut, status_code=status.HTTP_200_OK)
async def update_command(command_id: str, data: CommandUpdate) -> CommandOut:
    """
    Komut genel güncelleme endpoint'i.
    Komutun isteğe bağlı alanlarını toptan günceller.
    """
    return await update_command_service(command_id, data)


@router.patch("/{command_id}/intent", response_model=CommandOut, status_code=status.HTTP_200_OK)
async def update_command_intent(command_id: str, intent: str, confidence: float) -> CommandOut:
    """
    Komut amacı (intent) güncelleme endpoint'i.
    Komutun AI tarafından çıkarılmış intent (amaç) bilgisini confidence skoruyla günceller.
    """
    return await update_command_intent_service(command_id, intent, confidence)


@router.patch("/{command_id}/parameters", response_model=CommandOut, status_code=status.HTTP_200_OK)
async def update_command_parameters(command_id: str, parameters: dict) -> CommandOut:
    """
    Komut parametreleri güncelleme endpoint'i.
    Komutun ait olduğu parametreleri (örneğin ayıklanmış entity'leri) günceller.
    """
    return await update_command_parameters_service(command_id, parameters)


@router.delete("/{command_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_command(command_id: str) -> None:
    """
    Komut silme endpoint'i.
    Belirtilen ID'ye sahip komutu sistemden soft-delete yöntemiyle siler.
    """
    await delete_command_service(command_id)
