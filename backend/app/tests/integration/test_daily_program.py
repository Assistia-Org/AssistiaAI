import pytest
import httpx
from datetime import date
from app.models.user import User as UserModel
from app.models.daily_program import DailyProgram, DailyProgramSummary, DailyProgramItems

pytestmark = pytest.mark.asyncio

async def test_create_daily_program(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test successful creation of a daily program."""
    db_user = await UserModel.find_one(UserModel.email == "integrationtest@example.com")
    assert db_user is not None

    program_data = {
        "tarih": "2026-06-01",
        "kullanici_id": str(db_user.id),
        "ozet": {"task_sayisi": 0, "etkinlik_sayisi": 0},
        "items": {"tasks": [], "etkinlikler": []}
    }
    response = await async_client.post(
        "/api/v1/daily-programs/",
        json=program_data,
        headers=auth_headers
    )
    assert response.status_code == 201
    assert response.json()["tarih"] == "2026-06-01"

async def test_get_daily_program(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test retrieving daily program by ID."""
    db_user = await UserModel.find_one(UserModel.email == "integrationtest@example.com")
    
    # 1. Create one directly in DB
    program = DailyProgram(
        tarih=date(2026, 6, 2),
        kullanici_id=str(db_user.id),
        ozet=DailyProgramSummary(task_sayisi=0, etkinlik_sayisi=0),
        items=DailyProgramItems(tasks=[], etkinlikler=[])
    )
    await program.save()

    # 2. Get via endpoint
    response = await async_client.get(
        f"/api/v1/daily-programs/{program.id}",
        headers=auth_headers
    )
    assert response.status_code == 200
    assert response.json()["tarih"] == "2026-06-02"

async def test_get_program_by_date(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test retrieving daily program for the user by date."""
    db_user = await UserModel.find_one(UserModel.email == "integrationtest@example.com")

    program = DailyProgram(
        tarih=date(2026, 6, 3),
        kullanici_id=str(db_user.id),
        ozet=DailyProgramSummary(task_sayisi=0, etkinlik_sayisi=0),
        items=DailyProgramItems(tasks=[], etkinlikler=[])
    )
    await program.save()

    response = await async_client.get(
        "/api/v1/daily-programs/date/2026-06-03",
        headers=auth_headers
    )
    assert response.status_code == 200
    assert response.json()["tarih"] == "2026-06-03"

async def test_list_user_programs(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test listing all daily programs of the authenticated user."""
    db_user = await UserModel.find_one(UserModel.email == "integrationtest@example.com")

    # Create programs
    await DailyProgram(
        tarih=date(2026, 6, 4),
        kullanici_id=str(db_user.id),
        ozet=DailyProgramSummary(task_sayisi=0, etkinlik_sayisi=0),
        items=DailyProgramItems(tasks=[], etkinlikler=[])
    ).save()
    await DailyProgram(
        tarih=date(2026, 6, 5),
        kullanici_id=str(db_user.id),
        ozet=DailyProgramSummary(task_sayisi=0, etkinlik_sayisi=0),
        items=DailyProgramItems(tasks=[], etkinlikler=[])
    ).save()

    response = await async_client.get(
        "/api/v1/daily-programs/",
        headers=auth_headers
    )
    assert response.status_code == 200
    assert len(response.json()) >= 2

async def test_update_program(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test updating an existing daily program's task count or event count summary."""
    db_user = await UserModel.find_one(UserModel.email == "integrationtest@example.com")

    program = DailyProgram(
        tarih=date(2026, 6, 6),
        kullanici_id=str(db_user.id),
        ozet=DailyProgramSummary(task_sayisi=0, etkinlik_sayisi=0),
        items=DailyProgramItems(tasks=[], etkinlikler=[])
    )
    await program.save()

    update_data = {
        "ozet": {"task_sayisi": 5, "etkinlik_sayisi": 3}
    }
    response = await async_client.patch(
        f"/api/v1/daily-programs/{program.id}",
        json=update_data,
        headers=auth_headers
    )
    assert response.status_code == 200
    json_res = response.json()
    assert json_res["ozet"]["task_sayisi"] == 5
    assert json_res["ozet"]["etkinlik_sayisi"] == 3

async def test_delete_program(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test deleting a daily program record by ID."""
    db_user = await UserModel.find_one(UserModel.email == "integrationtest@example.com")

    program = DailyProgram(
        tarih=date(2026, 6, 7),
        kullanici_id=str(db_user.id),
        ozet=DailyProgramSummary(task_sayisi=0, etkinlik_sayisi=0),
        items=DailyProgramItems(tasks=[], etkinlikler=[])
    )
    await program.save()

    delete_res = await async_client.delete(
        f"/api/v1/daily-programs/{program.id}",
        headers=auth_headers
    )
    assert delete_res.status_code == 204

    # Verify deleted
    db_program = await DailyProgram.get(program.id)
    assert db_program is None
