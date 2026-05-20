import unittest
from unittest.mock import patch, AsyncMock, MagicMock
from datetime import datetime, timezone
from fastapi import HTTPException

from app.services.invitation_service import (
    send_invitation_service,
    get_my_invitations_service,
    accept_invitation_service,
    reject_invitation_service,
)
from app.models.invitation import InvitationStatus
from app.models.user import PersonalSettingsModel
from app.schemas.invitation import InvitationCreate, InvitationFilter
from app.core.messages.error_message import (
    COMMUNITY_NOT_FOUND,
    INVITATION_NOT_FOUND,
    INVITATION_ALREADY_EXISTS,
    ALREADY_MEMBER,
    UNAUTHORIZED_INVITATION,
    USER_NOT_FOUND,
)


class DummyUser(str):
    """A lightweight dummy class subclassing str to seamlessly pass string/link validations."""

    def __new__(cls, id: str, *args, **kwargs):
        return super().__new__(cls, id)

    def __init__(self, id: str, username: str, display_name: str, email: str):
        self.id = id
        self._id = id
        self.username = username
        self.display_name = display_name
        self.email = email
        self.avatar_url = None
        self.personal_settings = PersonalSettingsModel()
        self.joined_communities = []
        self.created_at = datetime.now(timezone.utc)
        self.is_deleted = False
        self.created_by = None
        self.updated_by = None
        self.deleted_by = None
        self.hashed_password = "hashed_password"


class DummyCommunity(str):
    """A lightweight dummy class subclassing str to seamlessly pass string/link validations."""

    def __new__(cls, id: str, *args, **kwargs):
        return super().__new__(cls, id)

    def __init__(self, id: str, name: str, owner_id: str, type: str = "public"):
        self.id = id
        self._id = id
        self.name = name
        self.owner_id = owner_id
        self.type = type
        self.members = []
        self.created_at = datetime.now(timezone.utc)
        self.is_deleted = False
        self.created_by = None
        self.updated_by = None
        self.deleted_by = None
        self.description = "Test Description"


class DummyInvitation:
    """A lightweight dummy class representing an Invitation model."""

    def __init__(self, id: str, community: DummyCommunity, inviter: DummyUser, invitee: DummyUser, invitee_email: str, role: str = "member"):
        self.id = id
        self._id = id
        self.community = community
        self.inviter = inviter
        self.invitee = invitee
        self.invitee_email = invitee_email
        self.status = InvitationStatus.PENDING
        self.role = role
        self.created_at = datetime.now(timezone.utc)

    async def fetch_all_links(self):
        pass


class TestInvitationService(unittest.IsolatedAsyncioTestCase):
    """Test suite for Invitation Service."""

    def setUp(self) -> None:
        """Set up mock users, communities, and invitations using clean dummy classes."""
        self.mock_user = DummyUser("user123", "inviter", "Inviter User", "inviter@example.com")
        self.mock_invitee = DummyUser("invitee456", "invitee", "Invitee User", "invitee@example.com")
        self.mock_community = DummyCommunity("comm123", "Test Community", "user123")
        self.mock_invitation = DummyInvitation(
            "inv123",
            self.mock_community,
            self.mock_user,
            self.mock_invitee,
            "invitee@example.com"
        )

    @patch("app.services.invitation_service.get_community_by_id", new_callable=AsyncMock)
    @patch("app.services.invitation_service.get_user_by_email", new_callable=AsyncMock)
    @patch("app.services.invitation_service.get_pending_invitation", new_callable=AsyncMock)
    @patch("app.services.invitation_service.create_invitation", new_callable=AsyncMock)
    @patch("app.services.invitation_service.event_manager.publish", new_callable=AsyncMock)
    @patch("app.services.invitation_service.create_notification_service", new_callable=AsyncMock)
    async def test_send_invitation_success(
        self,
        mock_create_notif: AsyncMock,
        mock_publish: AsyncMock,
        mock_create_inv: AsyncMock,
        mock_pending: AsyncMock,
        mock_get_user: AsyncMock,
        mock_get_comm: AsyncMock,
    ) -> None:
        """Test successful invitation sending."""
        mock_get_comm.return_value = self.mock_community
        mock_get_user.return_value = self.mock_invitee
        mock_pending.return_value = None
        mock_create_inv.return_value = self.mock_invitation

        data = InvitationCreate(
            community_id="comm123",
            invitee_email="invitee@example.com",
            role="member",
        )

        response = await send_invitation_service(self.mock_user, data)

        self.assertEqual(response.id, "inv123")
        mock_get_comm.assert_called_once_with("comm123")
        mock_get_user.assert_called_once_with("invitee@example.com")
        mock_pending.assert_called_once_with("comm123", "invitee@example.com")
        mock_create_inv.assert_called_once()
        mock_publish.assert_called_once()
        mock_create_notif.assert_called_once()

    @patch("app.services.invitation_service.get_community_by_id", new_callable=AsyncMock)
    async def test_send_invitation_community_not_found(self, mock_get_comm: AsyncMock) -> None:
        """Test sending invitation raises 404 if community does not exist."""
        mock_get_comm.return_value = None

        data = InvitationCreate(
            community_id="nonexistent",
            invitee_email="invitee@example.com",
            role="member",
        )

        with self.assertRaises(HTTPException) as ctx:
            await send_invitation_service(self.mock_user, data)

        self.assertEqual(ctx.exception.status_code, 404)
        self.assertEqual(ctx.exception.detail, COMMUNITY_NOT_FOUND)

    @patch("app.services.invitation_service.get_community_by_id", new_callable=AsyncMock)
    async def test_send_invitation_unauthorized(self, mock_get_comm: AsyncMock) -> None:
        """Test sending invitation raises 403 if inviter is not community owner."""
        self.mock_community.owner_id = "other_user"
        mock_get_comm.return_value = self.mock_community

        data = InvitationCreate(
            community_id="comm123",
            invitee_email="invitee@example.com",
            role="member",
        )

        with self.assertRaises(HTTPException) as ctx:
            await send_invitation_service(self.mock_user, data)

        self.assertEqual(ctx.exception.status_code, 403)
        self.assertEqual(ctx.exception.detail, UNAUTHORIZED_INVITATION)

    @patch("app.services.invitation_service.get_community_by_id", new_callable=AsyncMock)
    @patch("app.services.invitation_service.get_user_by_email", new_callable=AsyncMock)
    async def test_send_invitation_user_not_found(
        self, mock_get_user: AsyncMock, mock_get_comm: AsyncMock
    ) -> None:
        """Test sending invitation raises 404 if invitee does not exist."""
        mock_get_comm.return_value = self.mock_community
        mock_get_user.return_value = None

        data = InvitationCreate(
            community_id="comm123",
            invitee_email="invitee@example.com",
            role="member",
        )

        with self.assertRaises(HTTPException) as ctx:
            await send_invitation_service(self.mock_user, data)

        self.assertEqual(ctx.exception.status_code, 404)
        self.assertEqual(ctx.exception.detail, USER_NOT_FOUND)

    @patch("app.services.invitation_service.get_community_by_id", new_callable=AsyncMock)
    @patch("app.services.invitation_service.get_user_by_email", new_callable=AsyncMock)
    async def test_send_invitation_already_member(
        self, mock_get_user: AsyncMock, mock_get_comm: AsyncMock
    ) -> None:
        """Test sending invitation raises 400 if invitee is already a member."""
        mock_get_comm.return_value = self.mock_community
        mock_get_user.return_value = self.mock_invitee
        
        # Add invitee to community members list
        member_mock = MagicMock()
        member_mock.user = self.mock_invitee
        self.mock_community.members = [member_mock]

        data = InvitationCreate(
            community_id="comm123",
            invitee_email="invitee@example.com",
            role="member",
        )

        with self.assertRaises(HTTPException) as ctx:
            await send_invitation_service(self.mock_user, data)

        self.assertEqual(ctx.exception.status_code, 400)
        self.assertEqual(ctx.exception.detail, ALREADY_MEMBER)

    @patch("app.services.invitation_service.get_user_invitations", new_callable=AsyncMock)
    async def test_get_my_invitations_success(self, mock_get_invitations: AsyncMock) -> None:
        """Test retrieving my invitations successfully."""
        mock_get_invitations.return_value = [self.mock_invitation]

        response = await get_my_invitations_service(self.mock_user, InvitationFilter())

        self.assertEqual(len(response), 1)
        self.assertEqual(response[0].id, "inv123")
        mock_get_invitations.assert_called_once_with(
            user_id="user123",
            status=None,
            fetch_links=True,
        )

    @patch("app.services.invitation_service.get_invitation_by_id", new_callable=AsyncMock)
    @patch("app.services.invitation_service.update_invitation", new_callable=AsyncMock)
    @patch("app.services.invitation_service.add_community_member", new_callable=AsyncMock)
    @patch("app.services.invitation_service.add_community_role", new_callable=AsyncMock)
    @patch("app.services.invitation_service.create_notification_service", new_callable=AsyncMock)
    @patch("app.services.invitation_service.CommunityMember")
    async def test_accept_invitation_success(
        self,
        mock_comm_member: MagicMock,
        mock_create_notif: AsyncMock,
        mock_add_role: AsyncMock,
        mock_add_member: AsyncMock,
        mock_update: AsyncMock,
        mock_get_by_id: AsyncMock,
    ) -> None:
        """Test successful invitation acceptance."""
        self.mock_invitation.invitee_email = "invitee@example.com"
        mock_get_by_id.return_value = self.mock_invitation

        response = await accept_invitation_service(self.mock_invitee, "inv123")

        self.assertEqual(response.id, "inv123")
        mock_get_by_id.assert_called_once_with("inv123", fetch_links=True)
        mock_update.assert_called_once()
        mock_add_member.assert_called_once_with("comm123", unittest.mock.ANY)
        mock_add_role.assert_called_once_with("invitee456", unittest.mock.ANY)
        mock_create_notif.assert_called_once()

    @patch("app.services.invitation_service.get_invitation_by_id", new_callable=AsyncMock)
    async def test_accept_invitation_not_found(self, mock_get_by_id: AsyncMock) -> None:
        """Test accepting non-existent or wrong invitee raises 404."""
        self.mock_invitation.invitee_email = "other@example.com"
        mock_get_by_id.return_value = self.mock_invitation

        with self.assertRaises(HTTPException) as ctx:
            await accept_invitation_service(self.mock_invitee, "inv123")

        self.assertEqual(ctx.exception.status_code, 404)
        self.assertEqual(ctx.exception.detail, INVITATION_NOT_FOUND)

    @patch("app.services.invitation_service.get_invitation_by_id", new_callable=AsyncMock)
    @patch("app.services.invitation_service.update_invitation", new_callable=AsyncMock)
    @patch("app.services.invitation_service.create_notification_service", new_callable=AsyncMock)
    async def test_reject_invitation_success(
        self,
        mock_create_notif: AsyncMock,
        mock_update: AsyncMock,
        mock_get_by_id: AsyncMock,
    ) -> None:
        """Test successful invitation rejection."""
        self.mock_invitation.invitee_email = "invitee@example.com"
        mock_get_by_id.return_value = self.mock_invitation

        response = await reject_invitation_service(self.mock_invitee, "inv123")

        self.assertEqual(response.id, "inv123")
        mock_get_by_id.assert_called_once_with("inv123", fetch_links=True)
        mock_update.assert_called_once_with(self.mock_invitation, {"status": InvitationStatus.REJECTED})
        mock_create_notif.assert_called_once()


if __name__ == "__main__":
    unittest.main()
