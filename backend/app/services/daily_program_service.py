from datetime import date
from typing import List
from fastapi import HTTPException, status
from app.repositories.daily_program import (
    create_daily_program,
    get_daily_program_by_id,
    get_program_by_user_and_date,
    list_programs_by_user,
    update_daily_program,
    delete_daily_program
)
from app.schemas.daily_program import (
    DailyProgramCreate, 
    DailyProgramUpdate, 
    DailyProgramResponse
)
from app.core.messages.error_message import PROGRAM_NOT_FOUND

async def create_daily_program_service(data: DailyProgramCreate) -> DailyProgramResponse:
    """
    Business logic for creating a daily program.
    Ensures summary counts are updated based on items.
    """
    program_dict = data.model_dump()
    
    # Calculate summary based on items provided
    program_dict["ozet"]["task_sayisi"] = len(program_dict["items"]["tasks"])
    program_dict["ozet"]["etkinlik_sayisi"] = len(program_dict["items"]["etkinlikler"])
    
    program = await create_daily_program(program_dict)
    return DailyProgramResponse.model_validate(program)

async def get_daily_program_service(program_id: str) -> DailyProgramResponse:
    """
    Retrieve a daily program and validate existence.
    """
    program = await get_daily_program_by_id(program_id)
    if not program:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=PROGRAM_NOT_FOUND)
    return DailyProgramResponse.model_validate(program)

async def get_program_by_date_service(user_id: str, search_date: date) -> DailyProgramResponse:
    """
    Retrieve user's program for a specific date.
    """
    program = await get_program_by_user_and_date(user_id, search_date)
    if not program:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=PROGRAM_NOT_FOUND)
    return DailyProgramResponse.model_validate(program)

async def list_user_programs_service(user_id: str) -> List[DailyProgramResponse]:
    """
    List all programs for a user.
    """
    programs = await list_programs_by_user(user_id)
    return [DailyProgramResponse.model_validate(p) for p in programs]

async def update_daily_program_service(program_id: str, data: DailyProgramUpdate) -> DailyProgramResponse:
    """
    Update daily program and recalculate summary if items change.
    """
    program = await get_daily_program_by_id(program_id)
    if not program:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=PROGRAM_NOT_FOUND)
    
    update_dict = data.model_dump(exclude_unset=True)
    
    if "items" in update_dict:
        # Recalculate summary
        update_dict["ozet"] = {
            "task_sayisi": len(update_dict["items"].get("tasks", program.items.tasks)),
            "etkinlik_sayisi": len(update_dict["items"].get("etkinlikler", program.items.etkinlikler))
        }

    updated_program = await update_daily_program(program, update_dict)
    return DailyProgramResponse.model_validate(updated_program)

async def delete_daily_program_service(program_id: str) -> None:
    """
    Delete a daily program.
    """
    program = await get_daily_program_by_id(program_id)
    if not program:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=PROGRAM_NOT_FOUND)
    await delete_daily_program(program)
