from datetime import date
from typing import List
from fastapi import APIRouter, status, Depends
from app.schemas.daily_program import (
    DailyProgramCreate, 
    DailyProgramUpdate, 
    DailyProgramResponse
)
from app.services.daily_program_service import (
    create_daily_program_service,
    get_daily_program_service,
    get_program_by_date_service,
    list_user_programs_service,
    update_daily_program_service,
    delete_daily_program_service
)
from app.api.dependencies.auth import get_current_user
from app.models.user import User

router = APIRouter(prefix="/daily-programs", tags=["daily-programs"])

@router.post("/", response_model=DailyProgramResponse, status_code=status.HTTP_201_CREATED)
async def create_program(
    data: DailyProgramCreate,
    current_user: User = Depends(get_current_user)
) -> DailyProgramResponse:
    """
    Create a new daily program.
    """
    return await create_daily_program_service(data)

@router.get("/{program_id}", response_model=DailyProgramResponse, status_code=status.HTTP_200_OK)
async def get_program(
    program_id: str,
    current_user: User = Depends(get_current_user)
) -> DailyProgramResponse:
    """
    Get a daily program by ID.
    """
    return await get_daily_program_service(program_id)

@router.get("/user/{user_id}/date/{program_date}", response_model=DailyProgramResponse, status_code=status.HTTP_200_OK)
async def get_program_by_date(
    user_id: str, 
    program_date: date,
    current_user: User = Depends(get_current_user)
) -> DailyProgramResponse:
    """
    Get daily program for a specific user and date.
    """
    return await get_program_by_date_service(user_id, program_date)

@router.get("/user/{user_id}", response_model=List[DailyProgramResponse], status_code=status.HTTP_200_OK)
async def list_user_programs(
    user_id: str,
    current_user: User = Depends(get_current_user)
) -> List[DailyProgramResponse]:
    """
    List all daily programs for a user.
    """
    return await list_user_programs_service(user_id)

@router.patch("/{program_id}", response_model=DailyProgramResponse, status_code=status.HTTP_200_OK)
async def update_program(
    program_id: str, 
    data: DailyProgramUpdate,
    current_user: User = Depends(get_current_user)
) -> DailyProgramResponse:
    """
    Update an existing daily program record.
    """
    return await update_daily_program_service(program_id, data)

@router.delete("/{program_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_program(
    program_id: str,
    current_user: User = Depends(get_current_user)
) -> None:
    """
    Delete a daily program from the system.
    """
    await delete_daily_program_service(program_id)
