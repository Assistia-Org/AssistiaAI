import pytest
import httpx
from app.models.user import User as UserModel
from app.models.community import Community
from app.models.invitation import Invitation, InvitationStatus

pytestmark = pytest.mark.asyncio

async def test_send_invitation(
    async_client: httpx.AsyncClient,
    auth_headers: dict
) -> None:
    """Test sending community invitation to an email address."""
    # 1. Register the invitee first so they exist in the system
    invitee_data = {
        "username": "invitedmember",
        "display_name": "Invited Member",
        "email": "invited_member@example.com",
        "password": "Password123"
    }
    invitee_res = await async_client.post("/api/v1/auth/register", json=invitee_data)
    assert invitee_res.status_code == 201

    # 2. Create a community
    community_res = await async_client.post(
        "/api/v1/communities/",
        json={"name": "Invite Club", "type": "public"},
        headers=auth_headers
    )
    assert community_res.status_code == 201
    community_id = community_res.json()["id"]

    # 3. Send invitation
    invite_data = {
        "community_id": community_id,
        "invitee_email": "invited_member@example.com"
    }
    response = await async_client.post(
        "/api/v1/invitations/",
        json=invite_data,
        headers=auth_headers
    )
    assert response.status_code == 201
    json_data = response.json()
    assert json_data["invitee_email"] == "invited_member@example.com"
    assert json_data["status"] == InvitationStatus.PENDING

async def test_get_my_invitations(
    async_client: httpx.AsyncClient,
    auth_headers: dict
) -> None:
    """Test retrieving invitations sent to current user."""
    db_user = await UserModel.find_one(UserModel.email == "integrationtest@example.com")
    assert db_user is not None

    # 1. Create a real inviter and a real community to link
    inviter = UserModel(
        username="inviteruser",
        display_name="Inviter User",
        email="inviter@example.com",
        hashed_password="mocked_hashed_password"
    )
    await inviter.save()

    community = Community(
        name="Invitation Get Club",
        type="public",
        owner_id=str(inviter.id)
    )
    await community.save()

    # 2. Create invitation directly in DB (setting BOTH invitee link and email)
    invitation = Invitation(
        community=community,
        inviter=inviter,
        invitee=db_user,
        invitee_email=db_user.email,
        status=InvitationStatus.PENDING
    )
    await invitation.save()

    # 3. Get invitations
    response = await async_client.post(
        "/api/v1/invitations/me",
        json={"status": "pending"},
        headers=auth_headers
    )
    assert response.status_code == 200
    assert len(response.json()) >= 1

async def test_accept_invitation(
    async_client: httpx.AsyncClient,
    auth_headers: dict
) -> None:
    """Test successfully accepting a pending community invitation."""
    db_user = await UserModel.find_one(UserModel.email == "integrationtest@example.com")
    assert db_user is not None

    # 1. Create a real inviter and a real community to link
    inviter = UserModel(
        username="inviteruser2",
        display_name="Inviter User 2",
        email="inviter2@example.com",
        hashed_password="mocked_hashed_password"
    )
    await inviter.save()

    community = Community(
        name="Acceptance Club",
        type="public",
        owner_id=str(inviter.id)
    )
    await community.save()

    invitation = Invitation(
        community=community,
        inviter=inviter,
        invitee=db_user,
        invitee_email=db_user.email,
        status=InvitationStatus.PENDING
    )
    await invitation.save()

    # 2. Accept invitation
    response = await async_client.patch(
        f"/api/v1/invitations/{invitation.id}/accept",
        headers=auth_headers
    )
    assert response.status_code == 200
    assert response.json()["status"] == InvitationStatus.ACCEPTED

    # 3. Verify member added to community
    db_comm_updated = await Community.get(community.id)
    assert any(str(member.user.id) == str(db_user.id) for member in db_comm_updated.members)

async def test_reject_invitation(
    async_client: httpx.AsyncClient,
    auth_headers: dict
) -> None:
    """Test rejecting a pending community invitation."""
    db_user = await UserModel.find_one(UserModel.email == "integrationtest@example.com")
    assert db_user is not None

    # 1. Create a real inviter and a real community to link
    inviter = UserModel(
        username="inviteruser3",
        display_name="Inviter User 3",
        email="inviter3@example.com",
        hashed_password="mocked_hashed_password"
    )
    await inviter.save()

    community = Community(
        name="Rejection Club",
        type="public",
        owner_id=str(inviter.id)
    )
    await community.save()

    invitation = Invitation(
        community=community,
        inviter=inviter,
        invitee=db_user,
        invitee_email=db_user.email,
        status=InvitationStatus.PENDING
    )
    await invitation.save()

    # 2. Reject invitation
    response = await async_client.patch(
        f"/api/v1/invitations/{invitation.id}/reject",
        headers=auth_headers
    )
    assert response.status_code == 200
    assert response.json()["status"] == InvitationStatus.REJECTED
