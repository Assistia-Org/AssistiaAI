import pytest
import pytest_asyncio
import httpx
from app.models.community import Community, CommunityMember
from app.models.user import User as UserModel
from app.core.messages.error_message import (
    COMMUNITY_NOT_FOUND,
    UNAUTHORIZED_COMMUNITY_ACTION,
    OWNER_CANNOT_LEAVE,
    CANNOT_REMOVE_SELF,
    MEMBER_NOT_FOUND
)
from app.core.messages.success_message import MEMBER_REMOVED, COMMUNITY_LEFT

pytestmark = pytest.mark.asyncio

@pytest_asyncio.fixture
async def second_user(async_client: httpx.AsyncClient) -> dict:
    """Create and return a second registered user dict for testing multi-user scenarios."""
    user_data = {
        "username": "seconduser",
        "display_name": "Second User",
        "email": "second@example.com",
        "password": "SecondPassword123"
    }
    response = await async_client.post("/api/v1/auth/register", json=user_data)
    assert response.status_code == 201
    return user_data

@pytest_asyncio.fixture
async def second_auth_headers(async_client: httpx.AsyncClient, second_user: dict) -> dict:
    """Login second registered user and return their Bearer token authorization headers."""
    login_data = {
        "email": second_user["email"],
        "password": second_user["password"]
    }
    response = await async_client.post("/api/v1/auth/login", json=login_data)
    assert response.status_code == 200
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

async def test_create_community_success(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test successful community creation by authenticated user."""
    community_data = {
        "name": "Integration Community",
        "type": "public",
        "description": "A beautiful test community"
    }
    response = await async_client.post(
        "/api/v1/communities/",
        json=community_data,
        headers=auth_headers
    )
    assert response.status_code == 201
    json_data = response.json()
    assert json_data["name"] == "Integration Community"
    assert json_data["type"] == "public"
    assert "id" in json_data
    assert "owner_id" in json_data
    assert len(json_data["members"]) == 1
    assert json_data["members"][0]["role"] == "owner"

async def test_create_community_unauthorized(async_client: httpx.AsyncClient) -> None:
    """Test community creation fails when user is not authenticated."""
    community_data = {
        "name": "Unauthorized Community",
        "type": "public"
    }
    response = await async_client.post("/api/v1/communities/", json=community_data)
    assert response.status_code == 401

async def test_get_community_details(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test successful community details retrieval by ID."""
    # 1. Create a community
    community_data = {"name": "Detail Community", "type": "private"}
    create_res = await async_client.post(
        "/api/v1/communities/",
        json=community_data,
        headers=auth_headers
    )
    community_id = create_res.json()["id"]

    # 2. Get details
    get_res = await async_client.get(
        f"/api/v1/communities/{community_id}",
        headers=auth_headers
    )
    assert get_res.status_code == 200
    assert get_res.json()["name"] == "Detail Community"

async def test_get_community_not_found(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test retrieval fails for a non-existent community ID."""
    response = await async_client.get(
        "/api/v1/communities/60f72671e626e25df1f95a0a",
        headers=auth_headers
    )
    assert response.status_code == 404
    assert response.json()["detail"] == COMMUNITY_NOT_FOUND

async def test_list_communities(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test retrieving list of all communities."""
    # Create two communities
    await async_client.post(
        "/api/v1/communities/",
        json={"name": "Comm 1", "type": "public"},
        headers=auth_headers
    )
    await async_client.post(
        "/api/v1/communities/",
        json={"name": "Comm 2", "type": "public"},
        headers=auth_headers
    )

    response = await async_client.get("/api/v1/communities/", headers=auth_headers)
    assert response.status_code == 200
    assert len(response.json()) >= 2

async def test_get_my_communities(
    async_client: httpx.AsyncClient,
    auth_headers: dict,
    second_auth_headers: dict
) -> None:
    """Test that /me endpoint returns only the communities the user belongs to."""
    # 1. First user creates community
    await async_client.post(
        "/api/v1/communities/",
        json={"name": "Owner Comm", "type": "public"},
        headers=auth_headers
    )

    # 2. Check /me for owner
    me_res = await async_client.get("/api/v1/communities/me", headers=auth_headers)
    assert len(me_res.json()) == 1
    assert me_res.json()[0]["name"] == "Owner Comm"

    # 3. Check /me for second user (should be empty)
    second_me_res = await async_client.get("/api/v1/communities/me", headers=second_auth_headers)
    assert len(second_me_res.json()) == 0

async def test_update_community_success(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test successful community details update by the owner."""
    # 1. Create community
    create_res = await async_client.post(
        "/api/v1/communities/",
        json={"name": "Old Name", "type": "public"},
        headers=auth_headers
    )
    community_id = create_res.json()["id"]

    # 2. Update community
    update_data = {
        "name": "New Awesome Name",
        "description": "Updated Description"
    }
    update_res = await async_client.patch(
        f"/api/v1/communities/{community_id}",
        json=update_data,
        headers=auth_headers
    )
    assert update_res.status_code == 200
    assert update_res.json()["name"] == "New Awesome Name"
    assert update_res.json()["description"] == "Updated Description"

async def test_update_community_unauthorized(
    async_client: httpx.AsyncClient,
    auth_headers: dict,
    second_auth_headers: dict
) -> None:
    """Test community update fails when attempted by non-owner."""
    # 1. Owner creates community
    create_res = await async_client.post(
        "/api/v1/communities/",
        json={"name": "Protected Comm", "type": "public"},
        headers=auth_headers
    )
    community_id = create_res.json()["id"]

    # 2. Second user attempts update
    update_res = await async_client.patch(
        f"/api/v1/communities/{community_id}",
        json={"name": "Hacked Name"},
        headers=second_auth_headers
    )
    assert update_res.status_code == 403
    assert update_res.json()["detail"] == UNAUTHORIZED_COMMUNITY_ACTION

async def test_delete_community_unauthorized(
    async_client: httpx.AsyncClient,
    auth_headers: dict,
    second_auth_headers: dict
) -> None:
    """Test community deletion fails when attempted by non-owner."""
    create_res = await async_client.post(
        "/api/v1/communities/",
        json={"name": "Safe Comm", "type": "public"},
        headers=auth_headers
    )
    community_id = create_res.json()["id"]

    delete_res = await async_client.delete(
        f"/api/v1/communities/{community_id}",
        headers=second_auth_headers
    )
    assert delete_res.status_code == 403
    assert delete_res.json()["detail"] == UNAUTHORIZED_COMMUNITY_ACTION

async def test_delete_community_success(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test successful community deletion by its owner."""
    create_res = await async_client.post(
        "/api/v1/communities/",
        json={"name": "Temp Comm", "type": "public"},
        headers=auth_headers
    )
    community_id = create_res.json()["id"]

    delete_res = await async_client.delete(
        f"/api/v1/communities/{community_id}",
        headers=auth_headers
    )
    assert delete_res.status_code == 204

    # Verify community is actually deleted
    get_res = await async_client.get(
        f"/api/v1/communities/{community_id}",
        headers=auth_headers
    )
    assert get_res.status_code == 404

async def test_remove_community_member_success(
    async_client: httpx.AsyncClient,
    auth_headers: dict,
    second_user: dict
) -> None:
    """Test successful community member removal by the owner."""
    # 1. Owner creates community
    create_res = await async_client.post(
        "/api/v1/communities/",
        json={"name": "Shared Comm", "type": "public"},
        headers=auth_headers
    )
    community_id = create_res.json()["id"]

    # 2. Add second user to community directly in DB
    db_community = await Community.get(community_id)
    db_second_user = await UserModel.find_one(UserModel.email == second_user["email"])
    
    db_community.members.append(CommunityMember(user=db_second_user, role="member"))
    await db_community.save()

    # 3. Owner removes second user via API
    remove_res = await async_client.delete(
        f"/api/v1/communities/{community_id}/members/{db_second_user.id}",
        headers=auth_headers
    )
    assert remove_res.status_code == 200
    assert remove_res.json() == MEMBER_REMOVED

    # 4. Verify member is removed
    details = await async_client.get(f"/api/v1/communities/{community_id}", headers=auth_headers)
    assert len(details.json()["members"]) == 1  # Only owner remains

async def test_remove_self_forbidden(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test owner cannot remove themselves from the community."""
    # 1. Owner creates community
    create_res = await async_client.post(
        "/api/v1/communities/",
        json={"name": "Self Comm", "type": "public"},
        headers=auth_headers
    )
    community_id = create_res.json()["id"]
    owner_id = create_res.json()["owner_id"]

    # 2. Attempt self-removal
    response = await async_client.delete(
        f"/api/v1/communities/{community_id}/members/{owner_id}",
        headers=auth_headers
    )
    assert response.status_code == 400
    assert response.json()["detail"] == CANNOT_REMOVE_SELF

async def test_leave_community_success(
    async_client: httpx.AsyncClient,
    auth_headers: dict,
    second_user: dict,
    second_auth_headers: dict
) -> None:
    """Test successful community exit by a member."""
    # 1. Owner creates community
    create_res = await async_client.post(
        "/api/v1/communities/",
        json={"name": "Leave Comm", "type": "public"},
        headers=auth_headers
    )
    community_id = create_res.json()["id"]

    # 2. Add second user to community directly in DB
    db_community = await Community.get(community_id)
    db_second_user = await UserModel.find_one(UserModel.email == second_user["email"])
    
    db_community.members.append(CommunityMember(user=db_second_user, role="member"))
    await db_community.save()

    # 3. Second user leaves community via API
    leave_res = await async_client.post(
        f"/api/v1/communities/{community_id}/leave",
        headers=second_auth_headers
    )
    assert leave_res.status_code == 200
    assert leave_res.json() == COMMUNITY_LEFT

    # 4. Verify member has left
    details = await async_client.get(f"/api/v1/communities/{community_id}", headers=auth_headers)
    assert len(details.json()["members"]) == 1

async def test_owner_cannot_leave(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test owner is restricted from leaving their own community."""
    create_res = await async_client.post(
        "/api/v1/communities/",
        json={"name": "Owner Stay Comm", "type": "public"},
        headers=auth_headers
    )
    community_id = create_res.json()["id"]

    response = await async_client.post(
        f"/api/v1/communities/{community_id}/leave",
        headers=auth_headers
    )
    assert response.status_code == 400
    assert response.json()["detail"] == OWNER_CANNOT_LEAVE
