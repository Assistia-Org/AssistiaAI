import pytest
import pytest_asyncio
import httpx
from datetime import datetime
from app.models.reservation import Reservation
from app.models.community import Community, CommunityMember
from app.models.user import User as UserModel
from app.core.messages.error_message import (
    RESERVATION_NOT_FOUND,
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

async def test_create_personal_reservation_success(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test successful creation of a personal reservation by authenticated user."""
    reservation_data = {
        "category": "flight",
        "title": "Flight to Paris",
        "details": {
            "pnr": "XY1234",
            "airline": "Air France",
            "flight_number": "AF123"
        },
        "start_date": "2026-06-01T10:00:00",
        "end_date": "2026-06-01T14:00:00",
        "status": "confirmed"
    }
    response = await async_client.post(
        "/api/v1/reservations/",
        json=reservation_data,
        headers=auth_headers
    )
    assert response.status_code == 201
    json_data = response.json()
    assert json_data["title"] == "Flight to Paris"
    assert json_data["category"] == "flight"
    assert "id" in json_data
    assert json_data["user_id"] is not None

async def test_create_reservation_unauthorized_community(
    async_client: httpx.AsyncClient,
    auth_headers: dict,
    other_auth_headers: dict
) -> None:
    """Test reservation creation fails when assigning to a community not owned by user."""
    # 1. Other user creates community
    community_res = await async_client.post(
        "/api/v1/communities/",
        json={"name": "Other's Community", "type": "public"},
        headers=other_auth_headers
    )
    community_id = community_res.json()["id"]

    # 2. First user attempts to create reservation assigning to other user's community
    reservation_data = {
        "community_id": community_id,
        "category": "hotel",
        "title": "Unpermitted Stay",
        "details": {"hotel_name": "Hilton"},
        "status": "pending"
    }
    response = await async_client.post(
        "/api/v1/reservations/",
        json=reservation_data,
        headers=auth_headers
    )
    assert response.status_code == 403
    assert response.json()["detail"] == UNAUTHORIZED_COMMUNITY_ACTION

async def test_get_reservation_by_id(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test successful retrieval of specific reservation by ID."""
    # 1. Create reservation
    reservation_data = {
        "category": "car_rental",
        "title": "Rental SUV",
        "details": {"company": "Hertz"},
        "status": "confirmed"
    }
    create_res = await async_client.post(
        "/api/v1/reservations/",
        json=reservation_data,
        headers=auth_headers
    )
    reservation_id = create_res.json()["id"]

    # 2. Get details
    get_res = await async_client.get(
        f"/api/v1/reservations/{reservation_id}",
        headers=auth_headers
    )
    assert get_res.status_code == 200
    assert get_res.json()["title"] == "Rental SUV"

async def test_get_reservation_not_found(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test retrieval fails for a non-existent reservation ID."""
    response = await async_client.get(
        "/api/v1/reservations/nonexistent_reservation_id_123",
        headers=auth_headers
    )
    assert response.status_code == 404
    assert response.json()["detail"] == RESERVATION_NOT_FOUND

async def test_list_user_reservations(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test retrieving list of reservations for a specific user."""
    # 1. Create two reservations
    await async_client.post(
        "/api/v1/reservations/",
        json={"category": "hotel", "title": "Stay 1", "details": {}, "status": "confirmed"},
        headers=auth_headers
    )
    await async_client.post(
        "/api/v1/reservations/",
        json={"category": "hotel", "title": "Stay 2", "details": {}, "status": "confirmed"},
        headers=auth_headers
    )

    # 2. Fetch logged-in user profile to get user_id
    user_res = await async_client.get("/api/v1/communities/me", headers=auth_headers)
    # We can get the creator user ID directly from a created reservation
    db_res = await Reservation.find_one()
    user_id = db_res.user_id

    # 3. List reservations by user_id
    list_res = await async_client.get(
        f"/api/v1/reservations/user/{user_id}",
        headers=auth_headers
    )
    assert list_res.status_code == 200
    assert len(list_res.json()) >= 2

async def test_update_reservation(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test successful reservation details update."""
    # 1. Create reservation
    create_res = await async_client.post(
        "/api/v1/reservations/",
        json={"category": "hotel", "title": "Initial Stay", "details": {}, "status": "confirmed"},
        headers=auth_headers
    )
    reservation_id = create_res.json()["id"]

    # 2. Update reservation
    update_data = {
        "title": "Updated Stay Title",
        "status": "cancelled"
    }
    update_res = await async_client.patch(
        f"/api/v1/reservations/{reservation_id}",
        json=update_data,
        headers=auth_headers
    )
    assert update_res.status_code == 200
    assert update_res.json()["title"] == "Updated Stay Title"
    assert update_res.json()["status"] == "cancelled"

async def test_delete_reservation_as_creator(async_client: httpx.AsyncClient, auth_headers: dict) -> None:
    """Test successful global reservation deletion by its creator."""
    # 1. Create reservation
    create_res = await async_client.post(
        "/api/v1/reservations/",
        json={"category": "hotel", "title": "Delete Stay", "details": {}, "status": "confirmed"},
        headers=auth_headers
    )
    reservation_id = create_res.json()["id"]

    # 2. Delete reservation
    delete_res = await async_client.delete(
        f"/api/v1/reservations/{reservation_id}",
        headers=auth_headers
    )
    assert delete_res.status_code == 204

    # 3. Verify it is gone
    get_res = await async_client.get(
        f"/api/v1/reservations/{reservation_id}",
        headers=auth_headers
    )
    assert get_res.status_code == 404

async def test_delete_reservation_as_assigned_member(
    async_client: httpx.AsyncClient,
    auth_headers: dict,
    other_user: dict,
    other_auth_headers: dict
) -> None:
    """Test that when an assigned non-creator user deletes a reservation, they are only unassigned."""
    # 1. First user (owner) creates community
    community_res = await async_client.post(
        "/api/v1/communities/",
        json={"name": "Assigned Community", "type": "public"},
        headers=auth_headers
    )
    community_id = community_res.json()["id"]

    # 2. Add other_user to community in DB
    db_community = await Community.get(community_id)
    db_other_user = await UserModel.find_one(UserModel.email == other_user["email"])
    
    db_community.members.append(CommunityMember(user=db_other_user, role="member"))
    await db_community.save()

    # 3. Creator creates reservation assigned to the other user
    reservation_data = {
        "community_id": community_id,
        "category": "flight",
        "title": "Group Flight",
        "details": {},
        "assigned_to": [str(db_other_user.id)],
        "status": "confirmed"
    }
    create_res = await async_client.post(
        "/api/v1/reservations/",
        json=reservation_data,
        headers=auth_headers
    )
    reservation_id = create_res.json()["id"]

    # 4. Other user deletes reservation via API
    delete_res = await async_client.delete(
        f"/api/v1/reservations/{reservation_id}",
        headers=other_auth_headers
    )
    assert delete_res.status_code == 204

    # 5. Verify reservation STILL EXISTS in DB but other user is unassigned
    db_reservation = await Reservation.get(reservation_id)
    assert db_reservation is not None
    assert str(db_other_user.id) not in db_reservation.assigned_to
