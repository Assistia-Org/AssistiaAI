import asyncio
from fastapi import APIRouter, Depends, Request
from fastapi.responses import StreamingResponse
from app.api.dependencies.auth import get_current_user
from app.models.user import User
from app.core.events import event_manager

router = APIRouter(prefix="/sse", tags=["sse"])

@router.get("/stream")
async def sse_stream(request: Request, current_user: User = Depends(get_current_user)):
    """
    Server-Sent Events endpoint for pushing real-time notifications to the client.
    """
    queue = event_manager.subscribe(str(current_user.id))

    async def event_generator():
        try:
            while True:
                # Disconnect if client leaves
                if await request.is_disconnected():
                    break
                
                # Wait for next event with a timeout to check for disconnects periodically
                try:
                    message = await asyncio.wait_for(queue.get(), timeout=15.0)
                    yield f"data: {message}\n\n"
                except asyncio.TimeoutError:
                    # Keep-alive heartbeat to prevent idle connections from closing
                    yield ": heartbeat\n\n"
                    
        except asyncio.CancelledError:
            pass
        finally:
            event_manager.unsubscribe(str(current_user.id), queue)

    return StreamingResponse(event_generator(), media_type="text/event-stream")
