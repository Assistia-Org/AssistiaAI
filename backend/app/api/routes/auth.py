from fastapi import APIRouter, status, Depends
from fastapi.responses import HTMLResponse
from fastapi.security import OAuth2PasswordRequestForm
from datetime import datetime, timezone
from app.core.config import settings
from app.repositories.user import get_user_by_reset_token
from app.utils.templates import get_reset_password_html, get_reset_error_html
from app.schemas.auth import LoginSchema, Token, TokenRefresh, ForgotPasswordRequest, ResetPasswordRequest
from app.schemas.user import UserCreate, UserResponse
from app.services.auth_service import (
    register_user_service, 
    login_service, 
    refresh_token_service,
    forgot_password_service,
    reset_password_service
)

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

@router.post("/forgot-password", status_code=status.HTTP_200_OK)
async def forgot_password(data: ForgotPasswordRequest) -> dict:
    """Send password reset email."""
    return await forgot_password_service(data)

@router.post("/reset-password", status_code=status.HTTP_200_OK)
async def reset_password(data: ResetPasswordRequest) -> dict:
    """Reset password using token."""
    return await reset_password_service(data)

@router.get("/reset-password", response_class=HTMLResponse)
async def reset_password_page(token: str):
    """Render a simple and beautiful password reset HTML page."""
    user = await get_user_by_reset_token(token)
    
    if not user:
        return HTMLResponse(content=get_reset_error_html("Geçersiz veya kullanılmış bağlantı."))
    
    if user.reset_token_expires_at.replace(tzinfo=timezone.utc) < datetime.now(timezone.utc):
        return HTMLResponse(content=get_reset_error_html("Bu bağlantının süresi dolmuş."))

    return HTMLResponse(content=get_reset_password_html(token))
