import unittest
from unittest.mock import patch, AsyncMock, MagicMock
from datetime import datetime, timezone
from fastapi import HTTPException

from app.services.community_service import (
    create_community_service,
    get_community_service,
    list_communities_service,
    get_my_communities_service,
    update_community_service,
    delete_community_service,
    remove_community_member_service,
    leave_community_service,
)
from app.schemas.community import CommunityCreate, CommunityUpdate
from app.models.user import User, PersonalSettingsModel
from app.core.messages.error_message import (
    COMMUNITY_NOT_FOUND,
    UNAUTHORIZED_COMMUNITY_ACTION,
    MEMBER_NOT_FOUND,
    CANNOT_REMOVE_SELF,
    OWNER_CANNOT_LEAVE,
)
from app.core.messages.success_message import MEMBER_REMOVED, COMMUNITY_LEFT


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


class DummyCommunity:
    """A lightweight dummy class representing a Community model to pass Pydantic validation."""

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

    async def fetch_all_links(self):
        pass


class TestCommunityService(unittest.IsolatedAsyncioTestCase):
    """Test suite for Community Service."""

    def setUp(self) -> None:
        """Set up dummy models and common test inputs."""
        self.mock_user = DummyUser("user123", "owner", "Owner User", "owner@example.com")
        self.mock_other_user = DummyUser("user456", "other", "Other User", "other@example.com")
        self.mock_community = DummyCommunity("comm123", "My Community", "user123")

    @patch("app.services.community_service.CommunityMember")
    @patch("app.services.community_service.create_community", new_callable=AsyncMock)
    @patch("app.services.community_service.logger", new_callable=AsyncMock)
    async def test_create_community_success(
        self, mock_logger: AsyncMock, mock_create: AsyncMock, mock_comm_member: MagicMock
    ) -> None:
        """Test successful community creation."""
        mock_create.return_value = self.mock_community

        data = CommunityCreate(name="My Community", type="public", description="A great group")
        response = await create_community_service(data, self.mock_user)

        self.assertEqual(response.id, "comm123")
        self.assertEqual(response.name, "My Community")
        mock_comm_member.assert_called_once()
        mock_create.assert_called_once()
        mock_logger.info.assert_called_once()

    @patch("app.services.community_service.get_community_by_id", new_callable=AsyncMock)
    async def test_get_community_success(self, mock_get_by_id: AsyncMock) -> None:
        """Test successful community retrieval by ID."""
        mock_get_by_id.return_value = self.mock_community

        response = await get_community_service("comm123")

        self.assertEqual(response.id, "comm123")
        mock_get_by_id.assert_called_once_with("comm123", fetch_links=True)

    @patch("app.services.community_service.get_community_by_id", new_callable=AsyncMock)
    async def test_get_community_not_found(self, mock_get_by_id: AsyncMock) -> None:
        """Test retrieving non-existent community raises 404."""
        mock_get_by_id.return_value = None

        with self.assertRaises(HTTPException) as ctx:
            await get_community_service("nonexistent")

        self.assertEqual(ctx.exception.status_code, 404)
        self.assertEqual(ctx.exception.detail, COMMUNITY_NOT_FOUND)

    @patch("app.services.community_service.list_communities", new_callable=AsyncMock)
    async def test_list_communities_success(self, mock_list: AsyncMock) -> None:
        """Test listing all communities."""
        mock_list.return_value = [self.mock_community]

        response = await list_communities_service()

        self.assertEqual(len(response), 1)
        self.assertEqual(response[0].id, "comm123")
        mock_list.assert_called_once()

    @patch("app.services.community_service.get_my_communities", new_callable=AsyncMock)
    async def test_get_my_communities_success(self, mock_get_my: AsyncMock) -> None:
        """Test retrieving user's communities."""
        mock_get_my.return_value = [self.mock_community]

        response = await get_my_communities_service("user123")

        self.assertEqual(len(response), 1)
        self.assertEqual(response[0].id, "comm123")
        mock_get_my.assert_called_once_with("user123", fetch_links=True)

    @patch("app.services.community_service.get_community_by_id", new_callable=AsyncMock)
    @patch("app.services.community_service.update_community", new_callable=AsyncMock)
    @patch("app.services.community_service.logger", new_callable=AsyncMock)
    async def test_update_community_success(
        self, mock_logger: AsyncMock, mock_update: AsyncMock, mock_get_by_id: AsyncMock
    ) -> None:
        """Test successful community update by owner."""
        mock_get_by_id.return_value = self.mock_community
        mock_update.return_value = self.mock_community

        data = CommunityUpdate(name="Updated Community Name")
        response = await update_community_service("comm123", data, self.mock_user)

        self.assertEqual(response.id, "comm123")
        mock_get_by_id.assert_called_once_with("comm123")
        mock_update.assert_called_once()
        mock_logger.info.assert_called_once()

    @patch("app.services.community_service.get_community_by_id", new_callable=AsyncMock)
    async def test_update_community_unauthorized(self, mock_get_by_id: AsyncMock) -> None:
        """Test community update by non-owner raises 403."""
        mock_get_by_id.return_value = self.mock_community

        data = CommunityUpdate(name="Updated Name")
        with self.assertRaises(HTTPException) as ctx:
            # self.mock_other_user is not the owner (user123 is owner)
            await update_community_service("comm123", data, self.mock_other_user)

        self.assertEqual(ctx.exception.status_code, 403)
        self.assertEqual(ctx.exception.detail, UNAUTHORIZED_COMMUNITY_ACTION)

    @patch("app.services.community_service.get_community_by_id", new_callable=AsyncMock)
    @patch("app.services.community_service.delete_community", new_callable=AsyncMock)
    @patch("app.services.community_service.logger", new_callable=AsyncMock)
    async def test_delete_community_success(
        self, mock_logger: AsyncMock, mock_delete: AsyncMock, mock_get_by_id: AsyncMock
    ) -> None:
        """Test successful community deletion by owner."""
        mock_get_by_id.return_value = self.mock_community

        await delete_community_service("comm123", self.mock_user)

        mock_get_by_id.assert_called_once_with("comm123")
        mock_delete.assert_called_once_with(self.mock_community)
        mock_logger.info.assert_called_once()

    @patch("app.services.community_service.get_community_by_id", new_callable=AsyncMock)
    @patch("app.services.community_service.remove_community_member", new_callable=AsyncMock)
    @patch("app.services.community_service.remove_community_role", new_callable=AsyncMock)
    @patch("app.services.community_service.logger", new_callable=AsyncMock)
    async def test_remove_community_member_success(
        self,
        mock_logger: AsyncMock,
        mock_remove_role: AsyncMock,
        mock_remove_member: AsyncMock,
        mock_get_by_id: AsyncMock,
    ) -> None:
        """Test successful member removal by community owner."""
        mock_get_by_id.return_value = self.mock_community
        mock_remove_member.return_value = True

        response = await remove_community_member_service("comm123", "user456", self.mock_user)

        self.assertEqual(response, MEMBER_REMOVED)
        mock_get_by_id.assert_called_once_with("comm123")
        mock_remove_member.assert_called_once_with("comm123", "user456")
        mock_remove_role.assert_called_once_with("user456", "comm123")
        mock_logger.info.assert_called_once()

    @patch("app.services.community_service.get_community_by_id", new_callable=AsyncMock)
    async def test_remove_community_member_self(self, mock_get_by_id: AsyncMock) -> None:
        """Test owner attempting to remove themselves raises 400."""
        mock_get_by_id.return_value = self.mock_community

        with self.assertRaises(HTTPException) as ctx:
            # user123 is owner, trying to remove user123
            await remove_community_member_service("comm123", "user123", self.mock_user)

        self.assertEqual(ctx.exception.status_code, 400)
        self.assertEqual(ctx.exception.detail, CANNOT_REMOVE_SELF)

    @patch("app.services.community_service.get_community_by_id", new_callable=AsyncMock)
    @patch("app.services.community_service.remove_community_member", new_callable=AsyncMock)
    @patch("app.services.community_service.remove_community_role", new_callable=AsyncMock)
    @patch("app.services.community_service.logger", new_callable=AsyncMock)
    async def test_leave_community_success(
        self,
        mock_logger: AsyncMock,
        mock_remove_role: AsyncMock,
        mock_remove_member: AsyncMock,
        mock_get_by_id: AsyncMock,
    ) -> None:
        """Test successful community exit by standard member."""
        mock_get_by_id.return_value = self.mock_community
        mock_remove_member.return_value = True

        # self.mock_other_user (user456) is NOT the owner
        response = await leave_community_service("comm123", self.mock_other_user)

        self.assertEqual(response, COMMUNITY_LEFT)
        mock_get_by_id.assert_called_once_with("comm123")
        mock_remove_member.assert_called_once_with("comm123", "user456")
        mock_remove_role.assert_called_once_with("user456", "comm123")
        mock_logger.info.assert_called_once()

    @patch("app.services.community_service.get_community_by_id", new_callable=AsyncMock)
    async def test_leave_community_owner_cannot_leave(self, mock_get_by_id: AsyncMock) -> None:
        """Test owner leaving community raises 400."""
        mock_get_by_id.return_value = self.mock_community

        with self.assertRaises(HTTPException) as ctx:
            # self.mock_user (user123) is the owner
            await leave_community_service("comm123", self.mock_user)

        self.assertEqual(ctx.exception.status_code, 400)
        self.assertEqual(ctx.exception.detail, OWNER_CANNOT_LEAVE)


if __name__ == "__main__":
    unittest.main()
