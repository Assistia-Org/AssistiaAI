from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.api.dependencies.database import init_db
from app.api.routes.community import router as community_router
from app.api.routes.reservation import router as reservation_router
from app.api.routes.task import router as task_router
from app.api.routes.user import router as user_router
from app.api.routes.daily_program import router as daily_program_router
from app.api.routes.auth import router as auth_router
from app.api.routes.invitation import router as invitation_router
from app.core.config import settings

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup and shutdown events."""
    # Startup
    await init_db()
    yield
    # Shutdown
    # (Add cleanup logic here if needed)


from fastapi.middleware.cors import CORSMiddleware

def create_app() -> FastAPI:
    """FastAPI application factory."""
    app = FastAPI(
        title=settings.PROJECT_NAME,
        version="0.1.0",
        lifespan=lifespan,
    )

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

    @app.get("/health", tags=["health"])
    async def health_check():
        return {"status": "ok", "project": settings.PROJECT_NAME}

    return app


app = create_app()
