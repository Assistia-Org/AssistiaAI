from contextlib import asynccontextmanager
from fastapi import FastAPI
from backend.app.api.dependencies.database import init_db
from backend.app.api.routes.community import router as community_router
from backend.app.api.routes.reservation_controller import router as reservation_router
from backend.app.api.routes.task_controller import router as task_router
from backend.app.api.routes.user_controller import router as user_router
from backend.app.core.config import settings

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup and shutdown events."""
    # Startup
    await init_db()
    yield
    # Shutdown
    # (Add cleanup logic here if needed)


def create_app() -> FastAPI:
    """FastAPI application factory."""
    app = FastAPI(
        title=settings.PROJECT_NAME,
        version="0.1.0",
        lifespan=lifespan,
    )

    # Register routes
    app.include_router(community_router, prefix="/api/v1")
    app.include_router(reservation_router, prefix="/api/v1")
    app.include_router(task_router, prefix="/api/v1")
    app.include_router(user_router, prefix="/api/v1")

    @app.get("/health", tags=["health"])
    async def health_check():
        return {"status": "ok", "project": settings.PROJECT_NAME}

    return app


app = create_app()
