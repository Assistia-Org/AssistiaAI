from fastapi import APIRouter, status, Depends
from fastapi.security import OAuth2PasswordRequestForm
from app.schemas.auth import LoginSchema, Token, TokenRefresh
from app.schemas.user import UserCreate, UserResponse
from app.services.auth_service import register_user_service, login_service, refresh_token_service

router = APIRouter(prefix="/auth", tags=["auth"])

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(data: UserCreate) -> UserResponse:
    """Register a new user."""
    return await register_user_service(data)

@router.post("/login", response_model=Token, status_code=status.HTTP_200_OK)
async def login(data: LoginSchema) -> Token:
    """Login with email and password."""
    return await login_service(data)

@router.post("/refresh", response_model=Token, status_code=status.HTTP_200_OK)
async def refresh(data: TokenRefresh) -> Token:
    """Refresh access and refresh tokens."""
    return await refresh_token_service(data)

@router.post("/login/swagger", response_model=Token, status_code=status.HTTP_200_OK, include_in_schema=False)
async def login_swagger(form_data: OAuth2PasswordRequestForm = Depends()) -> Token:
    """Login specifically for Swagger UI Authorize button (OAuth2 compatible)."""
    return await login_service(LoginSchema(email=form_data.username, password=form_data.password))
