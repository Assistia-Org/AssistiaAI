import asyncio
from typing import Dict, List, Any
import json

class EventManager:
    def __init__(self):
        # Maps user_id -> List of queues (for multiple active connections)
        self.listeners: Dict[str, List[asyncio.Queue]] = {}

    def subscribe(self, user_id: str) -> asyncio.Queue:
        if user_id not in self.listeners:
            self.listeners[user_id] = []
        queue = asyncio.Queue()
        self.listeners[user_id].append(queue)
        return queue

    def unsubscribe(self, user_id: str, queue: asyncio.Queue):
        if user_id in self.listeners:
            if queue in self.listeners[user_id]:
                self.listeners[user_id].remove(queue)
            if not self.listeners[user_id]:
                del self.listeners[user_id]

    async def publish(self, user_id: str, event_type: str, data: Any = None):
        """
        Publishes a message to all queues of a specific user.
        """
        if user_id in self.listeners:
            message = {
                "type": event_type,
                "data": data or {}
            }
            message_str = json.dumps(message)
            for queue in self.listeners[user_id]:
                await queue.put(message_str)

# Global singleton
event_manager = EventManager()
