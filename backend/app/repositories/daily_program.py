from datetime import date
from typing import List, Optional
from app.models.daily_program import DailyProgram

async def create_daily_program(data: dict) -> DailyProgram:
    """
    Create a new DailyProgram document.
    """
    program = DailyProgram(**data)
    return await program.insert()

async def get_daily_program_by_id(program_id: str) -> Optional[DailyProgram]:
    """
    Find a DailyProgram by its ID.
    """
    return await DailyProgram.get(program_id)

async def get_program_by_user_and_date(user_id: str, search_date: date) -> Optional[DailyProgram]:
    """
    Find a DailyProgram for a specific user on a specific date.
    """
    return await DailyProgram.find_one(
        DailyProgram.kullanici_id == user_id,
        DailyProgram.tarih == search_date
    )

async def list_programs_by_user(user_id: str) -> List[DailyProgram]:
    """
    List all DailyProgram documents belongs to a user.
    """
    return await DailyProgram.find(DailyProgram.kullanici_id == user_id).to_list()

async def update_daily_program(program: DailyProgram, update_data: dict) -> DailyProgram:
    """
    Update an existing DailyProgram document.
    """
    for key, value in update_data.items():
        if hasattr(program, key):
            setattr(program, key, value)
    return await program.save()

async def delete_daily_program(program: DailyProgram) -> None:
    """
    Delete a DailyProgram document.
    """
    await program.delete()

async def get_my_daily_programs(
    user_id: str,
    search_date: Optional[date] = None
) -> List[DailyProgram]:
    """
    Get the user's daily programs for a specific date.
    If no date is provided, today's date is used.
    """
    target_date = search_date or date.today()

    return await DailyProgram.find(
        DailyProgram.kullanici_id == user_id,
        DailyProgram.tarih == target_date
    ).to_list()