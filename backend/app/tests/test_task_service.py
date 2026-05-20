import unittest
from unittest.mock import patch, AsyncMock, MagicMock
from datetime import datetime, date, timezone, timedelta
from fastapi import HTTPException

from app.services.task_service import (
    sync_task_status,
    create_task_service,
    get_task_service,
    list_tasks_by_user_service,
    list_all_tasks_service,
    update_task_service,
    delete_task_service,
)
from app.schemas.task import TaskCreate, TaskUpdate
from app.models.task import TaskStatus, Task
from app.models.user import User, PersonalSettingsModel
from app.core.messages.error_message import (
    TASK_NOT_FOUND,
    UNAUTHORIZED_COMMUNITY_ACTION,
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


class TestTaskService(unittest.IsolatedAsyncioTestCase):
    """Test suite for Task Service."""

    def setUp(self) -> None:
        """Set up standard mock user, mock task, and mock Beanie model class attributes."""
        # 1. Mock Beanie class attributes and query methods on Task class
        Task.parent_task_id = MagicMock()
        Task.id = MagicMock()
        
        self.mock_find_many = MagicMock()
        self.mock_find_many.to_list = AsyncMock(return_value=[])
        Task.find = MagicMock(return_value=self.mock_find_many)

        self.mock_user = DummyUser("user123", "owner", "Owner User", "owner@example.com")
        self.mock_other_user = DummyUser("user456", "other", "Other User", "other@example.com")

        # 2. Mock Task instance
        self.mock_task = MagicMock()
        self.mock_task.id = "task123"
        self.mock_task._id = "task123"
        self.mock_task.creator_id = "user123"
        self.mock_task.community_id = "comm123"
        self.mock_task.category = "general"
        self.mock_task.title = "Test Task"
        self.mock_task.details = {}
        self.mock_task.assigned_to = ["user123"]
        self.mock_task.status = TaskStatus.PENDING
        self.mock_task.due_date = datetime.now(timezone.utc)
        self.mock_task.start_date = datetime.now(timezone.utc)
        self.mock_task.end_date = datetime.now(timezone.utc) + timedelta(days=1)
        self.mock_task.parent_task_id = "task123"
        self.mock_task.community_name = None
        self.mock_task.type = "todo"
        self.mock_task.description = "Test Task Description"
        self.mock_task.priority = "medium"
        self.mock_task.location_address = None

        self.mock_task.created_at = datetime.now(timezone.utc)
        self.mock_task.updated_at = None
        self.mock_task.deleted_at = None
        self.mock_task.is_deleted = False
        self.mock_task.created_by = None
        self.mock_task.updated_by = None
        self.mock_task.deleted_by = None
        self.mock_task.save = AsyncMock()

        # 3. Mock DailyProgram model
        self.mock_program = MagicMock()
        self.mock_program.id = "prog123"
        self.mock_program._id = "prog123"
        self.mock_program.items = MagicMock()
        self.mock_program.items.tasks = []
        self.mock_program.ozet = MagicMock()
        self.mock_program.ozet.task_sayisi = 0
        self.mock_program.save = AsyncMock()

    async def test_sync_task_status_completed(self) -> None:
        """Test that sync_task_status keeps COMPLETED status unchanged."""
        self.mock_task.status = TaskStatus.COMPLETED
        result = await sync_task_status(self.mock_task)
        self.assertEqual(result.status, TaskStatus.COMPLETED)
        self.mock_task.save.assert_not_called()

    async def test_sync_task_status_in_progress(self) -> None:
        """Test sync_task_status transitions to IN_PROGRESS when within start and end date."""
        self.mock_task.status = TaskStatus.PENDING
        self.mock_task.start_date = datetime.now(timezone.utc) - timedelta(hours=1)
        self.mock_task.end_date = datetime.now(timezone.utc) + timedelta(hours=1)
        
        result = await sync_task_status(self.mock_task)
        self.assertEqual(result.status, TaskStatus.IN_PROGRESS)
        self.mock_task.save.assert_called_once()

    async def test_sync_task_status_overdue(self) -> None:
        """Test sync_task_status transitions to OVERDUE when now is past end date."""
        self.mock_task.status = TaskStatus.PENDING
        self.mock_task.start_date = datetime.now(timezone.utc) - timedelta(hours=2)
        self.mock_task.end_date = datetime.now(timezone.utc) - timedelta(hours=1)
        
        result = await sync_task_status(self.mock_task)
        self.assertEqual(result.status, TaskStatus.OVERDUE)
        self.mock_task.save.assert_called_once()

    @patch("app.services.task_service.get_community_by_id", new_callable=AsyncMock)
    @patch("app.services.task_service.create_task", new_callable=AsyncMock)
    @patch("app.services.task_service.get_program_by_user_and_date", new_callable=AsyncMock)
    @patch("app.services.task_service.create_daily_program", new_callable=AsyncMock)
    @patch("app.services.notification_service.create_notification_service", new_callable=AsyncMock)
    @patch("app.services.task_service.logger", new_callable=AsyncMock)
    async def test_create_task_success(
        self,
        mock_logger: AsyncMock,
        mock_create_notif: AsyncMock,
        mock_create_program: AsyncMock,
        mock_get_program: AsyncMock,
        mock_create_task_db: AsyncMock,
        mock_get_community: AsyncMock,
    ) -> None:
        """Test successful task creation and distribution to target users."""
        # 1. Mock Community
        mock_comm = MagicMock()
        mock_comm.id = "comm123"
        mock_comm.name = "Test Community"
        mock_comm.owner_id = "user123"
        mock_get_community.return_value = mock_comm

        # 2. Mock Task Creation
        mock_create_task_db.return_value = self.mock_task

        # 3. Mock Program Retrieval and Sync
        mock_get_program.return_value = self.mock_program

        data = TaskCreate(
            creator_id="user123",
            community_id="comm123",
            category="general",
            title="Test Task",
            details={},
            assigned_to=["user123"],
            due_date=datetime.now(timezone.utc),
        )

        response = await create_task_service(self.mock_user, data)

        self.assertEqual(response.id, "task123")
        self.assertEqual(response.community_name, "Test Community")
        mock_get_community.assert_called_once_with("comm123")
        mock_create_task_db.assert_called_once()
        mock_get_program.assert_called_once()
        self.mock_program.save.assert_called_once()
        mock_logger.info.assert_called_once()

    @patch("app.services.task_service.get_community_by_id", new_callable=AsyncMock)
    async def test_create_task_unauthorized(self, mock_get_community: AsyncMock) -> None:
        """Test creating task in community by non-owner raises 403."""
        # Community owned by owner (user123)
        mock_comm = MagicMock()
        mock_comm.id = "comm123"
        mock_comm.owner_id = "user123"
        mock_get_community.return_value = mock_comm

        data = TaskCreate(
            creator_id="user123",
            community_id="comm123",
            category="general",
            title="Test Task",
            details={},
            assigned_to=["user123"],
        )

        with self.assertRaises(HTTPException) as ctx:
            # self.mock_other_user (user456) is NOT the owner
            await create_task_service(self.mock_other_user, data)

        self.assertEqual(ctx.exception.status_code, 403)
        self.assertEqual(ctx.exception.detail, UNAUTHORIZED_COMMUNITY_ACTION)

    @patch("app.services.task_service.get_task_by_id", new_callable=AsyncMock)
    @patch("app.services.task_service.get_community_by_id", new_callable=AsyncMock)
    async def test_get_task_success(
        self, mock_get_community: AsyncMock, mock_get_by_id: AsyncMock
    ) -> None:
        """Test successful task retrieval by ID."""
        mock_get_by_id.return_value = self.mock_task
        mock_get_community.return_value = MagicMock(name="Test Community")

        response = await get_task_service("task123")

        self.assertEqual(response.id, "task123")
        mock_get_by_id.assert_called_once_with("task123")

    @patch("app.services.task_service.get_task_by_id", new_callable=AsyncMock)
    async def test_get_task_not_found(self, mock_get_by_id: AsyncMock) -> None:
        """Test retrieving non-existent task raises 404."""
        mock_get_by_id.return_value = None

        with self.assertRaises(HTTPException) as ctx:
            await get_task_service("nonexistent")

        self.assertEqual(ctx.exception.status_code, 404)
        self.assertEqual(ctx.exception.detail, TASK_NOT_FOUND)

    @patch("app.services.task_service.get_tasks_by_user_id", new_callable=AsyncMock)
    @patch("app.services.task_service.get_community_by_id", new_callable=AsyncMock)
    async def test_list_tasks_by_user_success(
        self, mock_get_community: AsyncMock, mock_get_by_user: AsyncMock
    ) -> None:
        """Test listing tasks for a user."""
        mock_get_by_user.return_value = [self.mock_task]
        mock_get_community.return_value = None

        response = await list_tasks_by_user_service("user123")

        self.assertEqual(len(response), 1)
        self.assertEqual(response[0].id, "task123")
        mock_get_by_user.assert_called_once_with("user123")

    @patch("app.services.task_service.list_tasks", new_callable=AsyncMock)
    async def test_list_all_tasks_success(self, mock_list_tasks: AsyncMock) -> None:
        """Test listing all tasks."""
        mock_list_tasks.return_value = [self.mock_task]

        response = await list_all_tasks_service()

        self.assertEqual(len(response), 1)
        self.assertEqual(response[0].id, "task123")
        mock_list_tasks.assert_called_once()

    @patch("app.services.task_service.get_task_by_id", new_callable=AsyncMock)
    @patch("app.services.task_service.update_task", new_callable=AsyncMock)
    @patch("app.services.task_service.get_program_by_user_and_date", new_callable=AsyncMock)
    @patch("app.services.task_service.logger", new_callable=AsyncMock)
    async def test_update_task_success(
        self,
        mock_logger: AsyncMock,
        mock_get_program: AsyncMock,
        mock_update: AsyncMock,
        mock_get_by_id: AsyncMock,
    ) -> None:
        """Test successful task update by creator."""
        mock_get_by_id.return_value = self.mock_task
        mock_update.return_value = self.mock_task
        mock_get_program.return_value = self.mock_program

        data = TaskUpdate(title="New Task Title")
        response = await update_task_service("task123", data, self.mock_user)

        self.assertEqual(response.id, "task123")
        mock_get_by_id.assert_called_once_with("task123")
        mock_update.assert_called_once()
        mock_logger.info.assert_called_once()

    @patch("app.services.task_service.get_task_by_id", new_callable=AsyncMock)
    @patch("app.services.task_service.get_program_by_user_and_date", new_callable=AsyncMock)
    @patch("app.services.task_service.delete_task", new_callable=AsyncMock)
    @patch("app.services.task_service.logger", new_callable=AsyncMock)
    async def test_delete_task_by_creator_success(
        self,
        mock_logger: AsyncMock,
        mock_delete: AsyncMock,
        mock_get_program: AsyncMock,
        mock_get_by_id: AsyncMock,
    ) -> None:
        """Test successful task deletion by its creator (globally deletes split tasks)."""
        mock_get_by_id.return_value = self.mock_task
        
        # Configure Task.find to return our mock task copies
        self.mock_find_many.to_list.return_value = [self.mock_task]

        self.mock_program.items.tasks = [self.mock_task]
        mock_get_program.return_value = self.mock_program

        # self.mock_user is creator (user123)
        await delete_task_service("task123", self.mock_user)

        mock_get_by_id.assert_called_once_with("task123")
        mock_delete.assert_called_once_with(self.mock_task)
        mock_get_program.assert_called_once()
        self.mock_program.save.assert_called_once()
        mock_logger.warning.assert_called_once()

    @patch("app.services.task_service.get_task_by_id", new_callable=AsyncMock)
    @patch("app.services.task_service.get_program_by_user_and_date", new_callable=AsyncMock)
    @patch("app.services.task_service.delete_task", new_callable=AsyncMock)
    @patch("app.services.task_service.logger", new_callable=AsyncMock)
    async def test_delete_task_by_assignee_only_success(
        self,
        mock_logger: AsyncMock,
        mock_delete: AsyncMock,
        mock_get_program: AsyncMock,
        mock_get_by_id: AsyncMock,
    ) -> None:
        """Test successful task deletion by assignee (removes only own copy and own program link)."""
        # creator is user123, assignee is user456
        self.mock_task.creator_id = "user123"
        self.mock_task.assigned_to = ["user456"]
        mock_get_by_id.return_value = self.mock_task
        self.mock_program.items.tasks = [self.mock_task]
        mock_get_program.return_value = self.mock_program

        # self.mock_other_user is user456 (not creator)
        await delete_task_service("task123", self.mock_other_user)

        mock_get_by_id.assert_called_once_with("task123")
        mock_get_program.assert_called_once()
        self.mock_program.save.assert_called_once()
        mock_delete.assert_called_once_with(self.mock_task)
        mock_logger.info.assert_called_once()


if __name__ == "__main__":
    unittest.main()
