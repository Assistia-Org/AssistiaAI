import pytest
import pytest_asyncio
import httpx
from app.models.task import Task, TaskStatus
from app.models.community import Community, CommunityMember
from app.models.user import User as UserModel
from app.core.messages.error_message import (
    TASK_NOT_FOUND,
    UNAUTHORIZED_COMMUNITY_ACTION
)

pytestmark = pytest.mark.asyncio

@pytest_asyncio.fixture
async def other_user(async_client: httpx.AsyncClient) -> dict:
    """Create and return an alternative registered user dict for testing multi-user flows."""
    user_data = {
        "username": "otheruser",
        "display_name": "Other User",
        "email": "other@example.com",
        "password": "OtherPassword123"
    }
    response = await async_client.post("/api/v1/auth/register", json=user_data)
    assert response.status_code == 201
    return user_data

@pytest_asyncio.fixture
async def other_auth_headers(async_client: httpx.AsyncClient, other_user: dict) -> dict:
    """Login alternative registered user and return their Bearer token authorization headers."""
    login_data = {
        "email": other_user["email"],
        "password": other_user["password"]
    }
    response = await async_client.post("/api/v1/auth/login", json=login_data)
    assert response.status_code == 200
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

async def test_create_personal_task_success(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test successful creation of a personal task by authenticated user."""
    task_data = {
        "creator_id": "",
        "title": "Buy Groceries",
        "description": "Milk, eggs, and bread",
        "priority": "high",
        "status": "pending"
    }
    response = await async_client.post(
        "/api/v1/tasks/",
        json=task_data,
        headers=auth_headers
    )
    assert response.status_code == 201
    json_data = response.json()
    assert json_data["title"] == "Buy Groceries"
    assert json_data["priority"] == "high"
    assert "id" in json_data
    assert json_data["creator_id"] != ""

async def test_create_task_unauthorized_community(
    async_client: httpx.AsyncClient,
    auth_headers: dict,
    other_auth_headers: dict
) -> None:
    """Test task creation fails when assigning to a community not owned by the user."""
    # 1. Other user creates community
    community_res = await async_client.post(
        "/api/v1/communities/",
        json={"name": "Other's Community", "type": "public"},
        headers=other_auth_headers
    )
    community_id = community_res.json()["id"]

    # 2. First user attempts to create task under that community
    task_data = {
        "creator_id": "",
        "community_id": community_id,
        "title": "Malicious Task",
        "status": "pending"
    }
    response = await async_client.post(
        "/api/v1/tasks/",
        json=task_data,
        headers=auth_headers
    )
    assert response.status_code == 403
    assert response.json()["detail"] == UNAUTHORIZED_COMMUNITY_ACTION

async def test_get_task_by_id(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test successful retrieval of specific task by ID."""
    # 1. Create task
    create_res = await async_client.post(
        "/api/v1/tasks/",
        json={"creator_id": "", "title": "Read Book", "status": "pending"},
        headers=auth_headers
    )
    task_id = create_res.json()["id"]

    # 2. Get details
    get_res = await async_client.get(
        f"/api/v1/tasks/{task_id}",
        headers=auth_headers
    )
    assert get_res.status_code == 200
    assert get_res.json()["title"] == "Read Book"

async def test_get_task_not_found(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test retrieval fails for a non-existent task ID."""
    response = await async_client.get(
        "/api/v1/tasks/nonexistent_task_id_123",
        headers=auth_headers
    )
    assert response.status_code == 404
    assert response.json()["detail"] == TASK_NOT_FOUND

async def test_list_user_tasks(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test retrieving list of tasks for a specific user."""
    # 1. Create two tasks
    await async_client.post(
        "/api/v1/tasks/",
        json={"creator_id": "", "title": "Task 1", "status": "pending"},
        headers=auth_headers
    )
    await async_client.post(
        "/api/v1/tasks/",
        json={"creator_id": "", "title": "Task 2", "status": "pending"},
        headers=auth_headers
    )

    # 2. Fetch logged-in user profile to get user_id
    db_task = await Task.find_one()
    user_id = db_task.creator_id

    # 3. List tasks by user_id
    list_res = await async_client.get(
        f"/api/v1/tasks/user/{user_id}",
        headers=auth_headers
    )
    assert list_res.status_code == 200
    assert len(list_res.json()) >= 2

async def test_list_all_tasks(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test retrieving list of all tasks in the system."""
    await async_client.post(
        "/api/v1/tasks/",
        json={"creator_id": "", "title": "Global Task", "status": "pending"},
        headers=auth_headers
    )

    response = await async_client.get("/api/v1/tasks/", headers=auth_headers)
    assert response.status_code == 200
    assert len(response.json()) >= 1

async def test_update_task(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test successful task status and details update."""
    # 1. Create task
    create_res = await async_client.post(
        "/api/v1/tasks/",
        json={"creator_id": "", "title": "Initial Task", "status": "pending"},
        headers=auth_headers
    )
    task_id = create_res.json()["id"]

    # 2. Update status to completed
    update_data = {
        "title": "Finished Task",
        "status": "completed"
    }
    update_res = await async_client.patch(
        f"/api/v1/tasks/{task_id}",
        json=update_data,
        headers=auth_headers
    )
    assert update_res.status_code == 200
    assert update_res.json()["title"] == "Finished Task"
    assert update_res.json()["status"] == TaskStatus.COMPLETED

async def test_delete_task_as_creator(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test successful task deletion by its creator."""
    # 1. Create task
    create_res = await async_client.post(
        "/api/v1/tasks/",
        json={"creator_id": "", "title": "Delete Me", "status": "pending"},
        headers=auth_headers
    )
    task_id = create_res.json()["id"]

    # 2. Delete task
    delete_res = await async_client.delete(
        f"/api/v1/tasks/{task_id}",
        headers=auth_headers
    )
    assert delete_res.status_code == 204

    # 3. Verify it is deleted
    get_res = await async_client.get(
        f"/api/v1/tasks/{task_id}",
        headers=auth_headers
    )
    assert get_res.status_code == 404

async def test_delete_task_as_assignee(
    async_client: httpx.AsyncClient,
    auth_headers: dict,
    other_user: dict,
    other_auth_headers: dict
) -> None:
    """Test that when an assignee deletes their split task, only their copy is deleted."""
    # 1. First user creates community
    community_res = await async_client.post(
        "/api/v1/communities/",
        json={"name": "Split Community", "type": "public"},
        headers=auth_headers
    )
    community_id = community_res.json()["id"]

    # 2. Add other_user to community in DB
    db_community = await Community.get(community_id)
    db_other_user = await UserModel.find_one(UserModel.email == other_user["email"])
    
    db_community.members.append(CommunityMember(user=db_other_user, role="member"))
    await db_community.save()

    # 3. Creator creates task assigned to both (the creator and the other user)
    # This triggers the splitting logic, creating a copy for each user
    task_data = {
        "creator_id": "",
        "community_id": community_id,
        "title": "Group Work",
        "assigned_to": [str(db_other_user.id), str(db_community.owner_id)],
        "status": "pending"
    }
    create_res = await async_client.post(
        "/api/v1/tasks/",
        json=task_data,
        headers=auth_headers
    )
    parent_task_id = create_res.json()["parent_task_id"]

    # 4. Fetch the other user's split task copy from DB
    other_task = await Task.find_one(
        Task.parent_task_id == parent_task_id,
        Task.assigned_to == [str(db_other_user.id)]
    )
    assert other_task is not None

    # 5. Other user deletes their split copy
    delete_res = await async_client.delete(
        f"/api/v1/tasks/{other_task.id}",
        headers=other_auth_headers
    )
    assert delete_res.status_code == 204

    # 6. Verify other user's copy is deleted
    get_other_res = await async_client.get(
        f"/api/v1/tasks/{other_task.id}",
        headers=auth_headers
    )
    assert get_other_res.status_code == 404

    # 7. Verify creator's copy STILL EXISTS
    creator_task = await Task.find_one(
        Task.parent_task_id == parent_task_id,
        Task.assigned_to == [str(db_community.owner_id)]
    )
    assert creator_task is not None
