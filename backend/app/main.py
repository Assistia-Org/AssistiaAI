import time
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from app.api.dependencies.database import init_db
from app.core.redis import RedisClient
from app.core.firebase import init_firebase
from app.api.routes.community import router as community_router
from app.api.routes.reservation import router as reservation_router
from app.api.routes.task import router as task_router
from app.api.routes.user import router as user_router
from app.api.routes.daily_program import router as daily_program_router
from app.api.routes.auth import router as auth_router
from app.api.routes.invitation import router as invitation_router
from app.api.routes.verification import router as verification_router
from app.api.routes.sse import router as sse_router
from app.api.routes.notification import router as notification_router
from app.api.routes.assistant import router as assistant_router
from app.core.config import settings
from app.core.kafka_producer import start_producer, stop_producer
from app.core.logger import logger, EventType
from app.services.reminder_service import start_reminder_worker
import asyncio

class LoggingMiddleware(BaseHTTPMiddleware):
    """
    Her HTTP isteğini yakalar:
    - Başarılı istekler → API_REQUEST (INFO)
    - 4xx / 5xx hatalar → API_ERROR (WARNING / ERROR)

    Kullanıcı bilgisi:
    - JWT'den user_id (sub) çekilir  → minimal JWT best practice
    - Redis'ten username+email lookup → güncel veri, sıfır DB yükü
    """
    SKIP_PATHS = {"/health", "/docs", "/redoc", "/openapi.json"}

    @staticmethod
    def _extract_user_id(request: Request) -> str:
        """Authorization header'dan user_id (sub) döndürür."""
        try:
            from jose import jwt as jose_jwt
            auth = request.headers.get("Authorization", "")
            if not auth.startswith("Bearer "):
                return ""
            token = auth[7:]
            payload = jose_jwt.decode(
                token,
                settings.SECRET_KEY,
                algorithms=[settings.ALGORITHM],
                options={"verify_exp": False},
            )
            return str(payload.get("sub", ""))
        except Exception:
            return ""

    @staticmethod
    async def _get_user_info(user_id: str) -> tuple[str, str]:
        """Redis cache'den username ve email döndürür. Yoksa DB'den çeker ve cache'ler."""
        if not user_id:
            return "", ""
        try:
            from app.core.redis import get_redis_value, set_redis_value
            import json
            
            # 1. Redis'ten kontrol et
            raw = await get_redis_value(f"user_cache:{user_id}")
            if raw:
                data = json.loads(raw)
                return data.get("username", ""), data.get("email", "")
                
            # 2. Redis'te yoksa MongoDB'den çek
            from app.repositories.user import get_user_by_id
            user = await get_user_by_id(user_id)
            if user:
                username = user.username or ""
                email = user.email or ""
                
                # Redis'e yaz (24 saat)
                cache_val = json.dumps({"username": username, "email": email})
                await set_redis_value(f"user_cache:{user_id}", cache_val, expire=86400)
                
                return username, email
        except Exception:
            pass
        return "", ""

    async def dispatch(self, request: Request, call_next) -> Response:
        if request.url.path in self.SKIP_PATHS:
            return await call_next(request)

        user_id = self._extract_user_id(request)
        username, email = await self._get_user_info(user_id)

        start = time.perf_counter()
        import traceback
        
        try:
            response = await call_next(request)
            duration_ms = int((time.perf_counter() - start) * 1000)

            status_code = response.status_code
            is_error    = status_code >= 400
            level_fn    = logger.warning if 400 <= status_code < 500 else (
                          logger.error   if status_code >= 500 else logger.info)
            event_type  = EventType.API_ERROR if is_error else EventType.API_REQUEST

            await level_fn(
                event_type,
                f"{request.method} {request.url.path} → {status_code}",
                user_id=user_id,
                username=username,
                email=email,
                method=request.method,
                path=request.url.path,
                status_code=status_code,
                duration_ms=duration_ms,
                ip_address=request.client.host if request.client else "",
            )
            return response
            
        except Exception as e:
            duration_ms = int((time.perf_counter() - start) * 1000)
            tb_str = traceback.format_exc()
            
            await logger.error(
                EventType.API_ERROR,
                f"Unhandled Exception: {str(e)}\n\nTraceback:\n{tb_str}",
                user_id=user_id,
                username=username,
                email=email,
                method=request.method,
                path=request.url.path,
                status_code=500,
                duration_ms=duration_ms,
                ip_address=request.client.host if request.client else "",
            )
            raise  # Re-raise for FastAPI to return 500 Internal Server Error


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup and shutdown events."""
    # Startup
    await init_db()
    init_firebase()
    await start_producer()          # Kafka producer başlat
    await logger.info(
        EventType.SYSTEM_STARTUP,
        f"{settings.PROJECT_NAME} başlatıldı",
    )
    # Background tasks
    app.state.reminder_task = asyncio.create_task(start_reminder_worker())

    yield
    # Shutdown
    if hasattr(app.state, "reminder_task"):
        app.state.reminder_task.cancel()
        try:
            await app.state.reminder_task
        except asyncio.CancelledError:
            pass

    await logger.info(
        EventType.SYSTEM_SHUTDOWN,
        f"{settings.PROJECT_NAME} kapatılıyor",
    )
    await stop_producer()           # Kafka producer kapat
    await RedisClient.close()


from fastapi.middleware.cors import CORSMiddleware

def create_app() -> FastAPI:
    """FastAPI application factory."""
    app = FastAPI(
        title=settings.PROJECT_NAME,
        version="0.1.0",
        lifespan=lifespan,
    )

    # Loglama middleware — CORS'dan önce ekle
    app.add_middleware(LoggingMiddleware)

    # Configure CORS - allows frontend on localhost to access this backend
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"], # In production, restrict this to specific origins
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Register routes
    app.include_router(community_router, prefix="/api/v1")
    app.include_router(reservation_router, prefix="/api/v1")
    app.include_router(task_router, prefix="/api/v1")
    app.include_router(user_router, prefix="/api/v1")
    app.include_router(daily_program_router, prefix="/api/v1")
    app.include_router(auth_router, prefix="/api/v1")
    app.include_router(invitation_router, prefix="/api/v1")
    app.include_router(verification_router, prefix="/api/v1")
    app.include_router(sse_router, prefix="/api/v1")
    app.include_router(notification_router, prefix="/api/v1")
    app.include_router(assistant_router, prefix="/api/v1")

    @app.get("/health", tags=["health"])
    async def health_check():
        return {"status": "ok", "project": settings.PROJECT_NAME}

    return app


app = create_app()
