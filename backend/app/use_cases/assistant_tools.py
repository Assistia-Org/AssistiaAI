"""
Tool dispatcher for the AI assistant.

Each handle_* function maps one LLM tool call to the correct service layer.
This lives in use_cases/ because it orchestrates across multiple service
domains (tasks + reservations + communities) without violating the rule that
services must not call other services.
"""

import json
import logging
from datetime import date, datetime, timezone, timedelta
from typing import Any, Dict, List, Optional

from fastapi import HTTPException

from app.models.user import User
from app.repositories.community import get_my_communities
from app.schemas.reservation import ReservationCreate
from app.schemas.task import TaskCreate, TaskUpdate
from app.services.reservation_service import (
    create_reservation_service,
    list_reservations_by_user_service,
    update_reservation_service,
)
from app.services.task_service import (
    create_task_service,
    list_tasks_by_user_service,
    update_task_service,
)

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------


def _parse_iso(value: Optional[str]) -> Optional[datetime]:
    """Parse an ISO 8601 string returned by the LLM into a datetime."""
    if not value:
        return None
    try:
        return datetime.fromisoformat(value)
    except ValueError:
        return None


# ---------------------------------------------------------------------------
# Tool: create_task
# ---------------------------------------------------------------------------


async def handle_create_task(current_user: User, args: Dict[str, Any]) -> Dict[str, Any]:
    """
    Create a new task from LLM-extracted parameters.

    Raises HTTPException on validation or business-rule failures.
    """
    data = TaskCreate(
        creator_id=str(current_user.id),
        title=args.get("title", "Görev"),
        type=args.get("type", "Görev"),
        description=args.get("description"),
        due_date=_parse_iso(args.get("due_date")),
        start_date=_parse_iso(args.get("start_date")),
        end_date=_parse_iso(args.get("end_date")),
        priority=args.get("priority", "medium"),
        community_id=args.get("community_id"),
        assigned_to=args.get("assigned_to", []),
    )
    result = await create_task_service(current_user, data)
    return result.model_dump(mode="json")


# ---------------------------------------------------------------------------
# Tool: update_task
# ---------------------------------------------------------------------------


async def handle_update_task(current_user: User, args: Dict[str, Any]) -> Dict[str, Any]:
    """
    Update an existing task identified by task_id.

    Raises HTTPException when the task is not found or user is unauthorized.
    """
    task_id: Optional[str] = args.get("task_id")
    if not task_id:
        raise HTTPException(status_code=400, detail="task_id is required for update_task.")

    update_data = {}
    for key in ["title", "description", "priority", "status", "assigned_to", "tags"]:
        if key in args and args[key] is not None:
            update_data[key] = args[key]
            
    for key in ["due_date", "start_date", "end_date"]:
        if key in args and args[key] is not None:
            update_data[key] = _parse_iso(args[key])

    data = TaskUpdate(**update_data)
    result = await update_task_service(task_id, data)
    return result.model_dump(mode="json")


# ---------------------------------------------------------------------------
# Tool: complete_task
# ---------------------------------------------------------------------------


async def handle_complete_task(current_user: User, args: Dict[str, Any]) -> Dict[str, Any]:
    """
    Mark a task as completed using its task_id.

    This is a convenience wrapper around update_task that sets status=completed.
    """
    task_id: Optional[str] = args.get("task_id")
    if not task_id:
        raise HTTPException(status_code=400, detail="task_id is required for complete_task.")

    data = TaskUpdate(status="completed")
    result = await update_task_service(task_id, data)
    return result.model_dump(mode="json")


# ---------------------------------------------------------------------------
# Tool: create_reservation
# ---------------------------------------------------------------------------


async def handle_create_reservation(current_user: User, args: Dict[str, Any]) -> Dict[str, Any]:
    """
    Create a new reservation from LLM-extracted parameters.

    The LLM provides 'details' as a free-form dict with reservation-specific
    fields (room, location, airline, hotel, etc.).
    """
    raw_details = args.get("details", {})
    # LLM may serialize details as a JSON string — handle both
    if isinstance(raw_details, str):
        try:
            raw_details = json.loads(raw_details)
        except json.JSONDecodeError:
            raw_details = {"description": raw_details}

    data = ReservationCreate(
        user_id=str(current_user.id),
        category=args.get("category", "other"),
        title=args.get("title", "Rezervasyon"),
        details=raw_details,
        start_date=_parse_iso(args.get("start_date")),
        end_date=_parse_iso(args.get("end_date")),
        community_id=args.get("community_id"),
        assigned_to=args.get("assigned_to", []),
        is_shared=bool(args.get("is_shared", False)),
        status=args.get("status", "confirmed"),
    )
    result = await create_reservation_service(current_user, data)
    return result.model_dump(mode="json")


# ---------------------------------------------------------------------------
# Tool: update_reservation
# ---------------------------------------------------------------------------


async def handle_update_reservation(current_user: User, args: Dict[str, Any]) -> Dict[str, Any]:
    """
    Update an existing reservation identified by reservation_id.

    Raises HTTPException when the reservation is not found.
    """
    from app.schemas.reservation import ReservationUpdate

    reservation_id: Optional[str] = args.get("reservation_id")
    if not reservation_id:
        raise HTTPException(status_code=400, detail="reservation_id is required for update_reservation.")

    raw_details = args.get("details")
    if isinstance(raw_details, str):
        try:
            raw_details = json.loads(raw_details)
        except json.JSONDecodeError:
            raw_details = {"description": raw_details}

    data = ReservationUpdate(
        title=args.get("title"),
        details=raw_details,
        start_date=_parse_iso(args.get("start_date")),
        end_date=_parse_iso(args.get("end_date")),
        status=args.get("status"),
        assigned_to=args.get("assigned_to"),
        is_shared=args.get("is_shared"),
    )
    result = await update_reservation_service(reservation_id, data)
    return result.model_dump(mode="json")


# ---------------------------------------------------------------------------
# Tool: list_my_tasks
# ---------------------------------------------------------------------------


async def handle_list_my_tasks(current_user: User, args: Dict[str, Any]) -> Dict[str, Any]:
    """
    Return a summarised list of the current user's tasks.

    Returns a dict with 'count' and 'tasks' so the LLM can produce a
    concise natural-language summary without hitting token limits.
    """
    tasks = await list_tasks_by_user_service(str(current_user.id))
    return {
        "count": len(tasks),
        "tasks": [t.model_dump(mode="json") for t in tasks],
    }


# ---------------------------------------------------------------------------
# Tool: list_my_reservations
# ---------------------------------------------------------------------------


async def handle_list_my_reservations(current_user: User, args: Dict[str, Any]) -> Dict[str, Any]:
    """
    Return a summarised list of the current user's reservations.

    Returns a dict with 'count' and 'reservations'.
    """
    reservations = await list_reservations_by_user_service(str(current_user.id))
    return {
        "count": len(reservations),
        "reservations": [r.model_dump(mode="json") for r in reservations],
    }


# ---------------------------------------------------------------------------
# Tool: list_my_communities
# ---------------------------------------------------------------------------


async def handle_list_my_communities(current_user: User, args: Dict[str, Any]) -> Dict[str, Any]:
    """
    Return the communities the current user belongs to.

    The assistant calls this tool automatically before creating a community-
    scoped task/reservation so it can ask the user which community to use.
    """
    communities = await get_my_communities(str(current_user.id))
    return {
        "count": len(communities),
        "communities": [
            {"id": str(c.id), "name": c.name, "type": c.type}
            for c in communities
        ],
    }


# ---------------------------------------------------------------------------
# Tool: get_community_members
# ---------------------------------------------------------------------------


async def handle_get_community_members(current_user: User, args: Dict[str, Any]) -> Dict[str, Any]:
    """
    Return the member list of a specific community with names and IDs.

    Used before assign_task_to_community so the LLM can show the user
    who is in the community and ask which members to assign.
    """
    community_id: Optional[str] = args.get("community_id")
    if not community_id:
        raise HTTPException(status_code=400, detail="community_id is required for get_community_members.")

    from app.repositories.community import get_community_by_id
    from app.repositories.user import get_user_by_id

    community = await get_community_by_id(community_id, fetch_links=True)
    if not community:
        raise HTTPException(status_code=404, detail="Community not found.")

    members: List[Dict[str, Any]] = []
    for m in community.members:
        # m.user may be a Link or a resolved User object
        user_obj = m.user if hasattr(m.user, "display_name") else await get_user_by_id(str(getattr(m.user, "id", m.user)))
        if user_obj:
            members.append({
                "id": str(user_obj.id),
                "display_name": user_obj.display_name,
                "username": user_obj.username,
                "role": m.role,
            })

    return {
        "community_id": community_id,
        "community_name": community.name,
        "member_count": len(members),
        "members": members,
    }


# ---------------------------------------------------------------------------
# Tool: assign_task_to_community
# ---------------------------------------------------------------------------


async def handle_assign_task_to_community(current_user: User, args: Dict[str, Any]) -> Dict[str, Any]:
    """
    Create a community-scoped task and assign it to specific members.

    Flow the LLM should follow before calling this tool:
      1. list_my_communities   → user picks a community
      2. get_community_members → user picks which members to assign
      3. assign_task_to_community with community_id + assigned_to list

    If assigned_to is empty, the task is distributed to the entire community.
    """
    community_id: Optional[str] = args.get("community_id")
    if not community_id:
        raise HTTPException(status_code=400, detail="community_id is required for assign_task_to_community.")

    data = TaskCreate(
        creator_id=str(current_user.id),
        title=args.get("title", "Topluluk Görevi"),
        type=args.get("type", "Topluluk Görevi"),
        description=args.get("description"),
        due_date=_parse_iso(args.get("due_date")),
        start_date=_parse_iso(args.get("start_date")),
        end_date=_parse_iso(args.get("end_date")),
        priority=args.get("priority", "medium"),
        community_id=community_id,
        assigned_to=args.get("assigned_to", []),
        tags=args.get("tags", []),
    )
    result = await create_task_service(current_user, data)
    return result.model_dump(mode="json")


# ---------------------------------------------------------------------------
# Tool: get_daily_briefing
# ---------------------------------------------------------------------------


async def handle_get_daily_briefing(current_user: User, args: Dict[str, Any]) -> Dict[str, Any]:
    """
    Fetch the daily program (tasks + reservations) for the current user for a specific date.

    Returns a structured summary that the LLM uses to produce a natural-language
    briefing of the user's day — e.g. "Bugün 3 görevin ve 1 rezervasyonun var..."

    If no program document exists for today, falls back to raw task/reservation
    queries so the user always gets meaningful data.
    """
    from app.repositories.daily_program import get_program_by_user_and_date
    from app.repositories.task import get_task_by_id
    from app.services.task_service import sync_task_status

    user_id = str(current_user.id)
    target_date_str = args.get("target_date")
    target_date = _parse_iso(target_date_str).date() if target_date_str and _parse_iso(target_date_str) else date.today()

    program = await get_program_by_user_and_date(user_id, target_date)

    tasks_summary: List[Dict[str, Any]] = []
    reservations_summary: List[Dict[str, Any]] = []

    if program:
        await program.fetch_all_links()

        # Refresh task statuses
        for t in program.items.tasks:
            fresh = await get_task_by_id(str(t.id) if hasattr(t, "id") else str(t))
            if fresh:
                await sync_task_status(fresh)
                tasks_summary.append({
                    "id": str(fresh.id),
                    "title": fresh.title,
                    "status": fresh.status.value if hasattr(fresh.status, "value") else str(fresh.status),
                    "priority": fresh.priority,
                    "due_date": fresh.due_date.isoformat() if fresh.due_date else None,
                    "community_id": fresh.community_id,
                })

        for r in program.items.etkinlikler:
            res_obj = r if hasattr(r, "title") else None
            if res_obj:
                reservations_summary.append({
                    "id": str(res_obj.id),
                    "title": res_obj.title,
                    "category": res_obj.category,
                    "status": res_obj.status,
                    "start_date": res_obj.start_date.isoformat() if res_obj.start_date else None,
                })
    else:
        # No program document yet — fall back to direct queries for today
        all_tasks = await list_tasks_by_user_service(user_id)
        for t in all_tasks:
            due = t.due_date
            if due and due.date() == target_date if hasattr(due, "date") else due == target_date:
                tasks_summary.append({
                    "id": t.id,
                    "title": t.title,
                    "status": t.status.value if hasattr(t.status, "value") else str(t.status),
                    "priority": t.priority,
                    "due_date": t.due_date.isoformat() if t.due_date else None,
                    "community_id": t.community_id,
                })

        all_reservations = await list_reservations_by_user_service(user_id)
        for r in all_reservations:
            start = r.start_date
            if start and (start.date() == target_date if hasattr(start, "date") else start == target_date):
                reservations_summary.append({
                    "id": r.id,
                    "title": r.title,
                    "category": r.category,
                    "status": r.status,
                    "start_date": r.start_date.isoformat() if r.start_date else None,
                })

    return {
        "date": target_date.isoformat(),
        "task_count": len(tasks_summary),
        "reservation_count": len(reservations_summary),
        "tasks": tasks_summary,
        "reservations": reservations_summary,
        "has_program": program is not None,
    }


# ---------------------------------------------------------------------------
# Dispatcher registry
# ---------------------------------------------------------------------------

TOOL_HANDLERS = {
    "create_task": handle_create_task,
    "update_task": handle_update_task,
    "complete_task": handle_complete_task,
    "assign_task_to_community": handle_assign_task_to_community,
    "create_reservation": handle_create_reservation,
    "update_reservation": handle_update_reservation,
    "list_my_tasks": handle_list_my_tasks,
    "list_my_reservations": handle_list_my_reservations,
    "list_my_communities": handle_list_my_communities,
    "get_community_members": handle_get_community_members,
    "get_daily_briefing": handle_get_daily_briefing,
}


async def dispatch_tool(
    tool_name: str,
    args: Dict[str, Any],
    current_user: User,
) -> Dict[str, Any]:
    """
    Route a tool call produced by the LLM to the correct handler.

    Returns the handler's result dict, or raises HTTPException on error.
    """
    handler = TOOL_HANDLERS.get(tool_name)
    if not handler:
        raise HTTPException(status_code=400, detail=f"Unknown tool: {tool_name}")
    return await handler(current_user, args)
