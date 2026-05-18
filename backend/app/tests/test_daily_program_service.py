import unittest
from unittest.mock import patch, AsyncMock, MagicMock
from datetime import date, datetime, timezone
from fastapi import HTTPException

from app.services.daily_program_service import (
    create_daily_program_service,
    get_daily_program_service,
    get_program_by_date_service,
    list_user_programs_service,
    update_daily_program_service,
    delete_daily_program_service,
)
from app.schemas.daily_program import (
    DailyProgramCreate,
    DailyProgramUpdate,
    DailyProgramItemsSchema,
    DailyProgramSummarySchema,
)
from app.schemas.task import TaskResponse
from app.schemas.reservation import ReservationResponse
from app.core.messages.error_message import PROGRAM_NOT_FOUND


class TestDailyProgramService(unittest.IsolatedAsyncioTestCase):
    """Test suite for Daily Program Service."""

    def setUp(self) -> None:
        """Set up standard mocks and dummy inputs."""
        # Simple task response schema
        self.dummy_task_response = TaskResponse(
            id="task123",
            title="Clean Up Room",
            status="pending",
            due_date=datetime.now(timezone.utc),
            community_id="comm123",
            community_name=None,
            assigned_to=[],
            creator_id="user123",
            created_at=datetime.now(timezone.utc),
            is_deleted=False,
        )

        # Simple reservation response schema
        self.dummy_reservation_response = ReservationResponse(
            id="res123",
            title="Library Reservation",
            start_date=datetime.now(timezone.utc),
            user_id="user123",
            category="Toplantı",
            details={},
            status="pending",
            created_at=datetime.now(timezone.utc),
            is_deleted=False,
        )

        # Mock DB Daily Program Model
        self.mock_program = MagicMock()
        self.mock_program.id = "prog123"
        self.mock_program._id = "prog123"
        self.mock_program.tarih = date.today()
        self.mock_program.kullanici_id = "user123"
        self.mock_program.created_at = datetime.now(timezone.utc)
        self.mock_program.updated_at = None
        self.mock_program.deleted_at = None
        self.mock_program.is_deleted = False
        self.mock_program.created_by = None
        self.mock_program.updated_by = None
        self.mock_program.deleted_by = None
        
        # summary & items as mock properties
        self.mock_program.ozet = MagicMock()
        self.mock_program.ozet.task_sayisi = 1
        self.mock_program.ozet.etkinlik_sayisi = 1
        
        self.mock_program.items = MagicMock()
        self.mock_program.items.tasks = [self.dummy_task_response]
        self.mock_program.items.etkinlikler = [self.dummy_reservation_response]
        
        self.mock_program.fetch_all_links = AsyncMock()

    @patch("app.services.daily_program_service.create_daily_program", new_callable=AsyncMock)
    @patch("app.repositories.community.get_community_by_id", new_callable=AsyncMock)
    async def test_create_daily_program_success(
        self, mock_get_community: AsyncMock, mock_create: AsyncMock
    ) -> None:
        """Test successful daily program creation."""
        mock_create.return_value = self.mock_program
        
        # Mock community lookup for populating community names
        mock_community = MagicMock()
        mock_community.name = "Test Community"
        mock_get_community.return_value = mock_community

        data = DailyProgramCreate(
            tarih=date.today(),
            kullanici_id="user123",
            ozet=DailyProgramSummarySchema(task_sayisi=0, etkinlik_sayisi=0),
            items=DailyProgramItemsSchema(
                tasks=[self.dummy_task_response],
                etkinlikler=[self.dummy_reservation_response],
            ),
        )

        response = await create_daily_program_service(data)

        self.assertEqual(response.id, "prog123")
        self.assertEqual(response.ozet.task_sayisi, 1)
        self.assertEqual(response.items.tasks[0].community_name, "Test Community")
        mock_create.assert_called_once()
        mock_get_community.assert_called_once_with("comm123")

    @patch("app.services.daily_program_service.get_daily_program_by_id", new_callable=AsyncMock)
    @patch("app.repositories.community.get_community_by_id", new_callable=AsyncMock)
    async def test_get_daily_program_success(
        self, mock_get_community: AsyncMock, mock_get_by_id: AsyncMock
    ) -> None:
        """Test retrieving a daily program successfully."""
        mock_get_by_id.return_value = self.mock_program
        mock_get_community.return_value = None

        response = await get_daily_program_service("prog123")

        self.assertEqual(response.id, "prog123")
        mock_get_by_id.assert_called_once_with("prog123")

    @patch("app.services.daily_program_service.get_daily_program_by_id", new_callable=AsyncMock)
    async def test_get_daily_program_not_found(self, mock_get_by_id: AsyncMock) -> None:
        """Test retrieving non-existent daily program raises 404."""
        mock_get_by_id.return_value = None

        with self.assertRaises(HTTPException) as ctx:
            await get_daily_program_service("nonexistent")

        self.assertEqual(ctx.exception.status_code, 404)
        self.assertEqual(ctx.exception.detail, PROGRAM_NOT_FOUND)

    @patch("app.services.daily_program_service.get_program_by_user_and_date", new_callable=AsyncMock)
    @patch("app.repositories.task.get_task_by_id", new_callable=AsyncMock)
    @patch("app.services.daily_program_service.sync_task_status", new_callable=AsyncMock)
    @patch("app.repositories.community.get_community_by_id", new_callable=AsyncMock)
    async def test_get_program_by_date_success(
        self,
        mock_get_community: AsyncMock,
        mock_sync_status: AsyncMock,
        mock_get_task: AsyncMock,
        mock_get_by_date: AsyncMock,
    ) -> None:
        """Test retrieving program by date with fresh task syncs."""
        mock_get_by_date.return_value = self.mock_program
        
        # Mock fresh task lookup
        fresh_task_mock = TaskResponse(
            id="task123",
            title="Clean Up Room (Fresh)",
            status="completed",
            due_date=datetime.now(timezone.utc),
            community_id="comm123",
            community_name=None,
            assigned_to=[],
            creator_id="user123",
            created_at=datetime.now(timezone.utc),
            is_deleted=False,
        )

        mock_get_task.return_value = fresh_task_mock
        mock_get_community.return_value = None

        search_date = date.today()
        response = await get_program_by_date_service("user123", search_date)

        self.assertEqual(response.id, "prog123")
        self.assertEqual(response.items.tasks[0].title, "Clean Up Room (Fresh)")
        mock_get_by_date.assert_called_once_with("user123", search_date)
        self.mock_program.fetch_all_links.assert_called_once()
        mock_get_task.assert_called_once_with("task123")
        mock_sync_status.assert_called_once_with(fresh_task_mock)

    @patch("app.services.daily_program_service.get_program_by_user_and_date", new_callable=AsyncMock)
    async def test_get_program_by_date_not_found(self, mock_get_by_date: AsyncMock) -> None:
        """Test retrieve by date fails with 404 if program doesn't exist."""
        mock_get_by_date.return_value = None

        with self.assertRaises(HTTPException) as ctx:
            await get_program_by_date_service("user123", date.today())

        self.assertEqual(ctx.exception.status_code, 404)
        self.assertEqual(ctx.exception.detail, PROGRAM_NOT_FOUND)

    @patch("app.services.daily_program_service.list_programs_by_user", new_callable=AsyncMock)
    @patch("app.repositories.task.get_task_by_id", new_callable=AsyncMock)
    @patch("app.services.daily_program_service.sync_task_status", new_callable=AsyncMock)
    @patch("app.repositories.community.get_community_by_id", new_callable=AsyncMock)
    async def test_list_user_programs_success(
        self,
        mock_get_community: AsyncMock,
        mock_sync_status: AsyncMock,
        mock_get_task: AsyncMock,
        mock_list_user: AsyncMock,
    ) -> None:
        """Test listing programs for a user successfully."""
        mock_list_user.return_value = [self.mock_program]
        mock_get_task.return_value = None  # means task not found fresh, falls back
        mock_get_community.return_value = None

        response = await list_user_programs_service("user123")

        self.assertEqual(len(response), 1)
        self.assertEqual(response[0].id, "prog123")
        mock_list_user.assert_called_once_with("user123")
        self.mock_program.fetch_all_links.assert_called_once()

    @patch("app.services.daily_program_service.get_daily_program_by_id", new_callable=AsyncMock)
    @patch("app.services.daily_program_service.update_daily_program", new_callable=AsyncMock)
    @patch("app.repositories.community.get_community_by_id", new_callable=AsyncMock)
    async def test_update_daily_program_success(
        self,
        mock_get_community: AsyncMock,
        mock_update: AsyncMock,
        mock_get_by_id: AsyncMock,
    ) -> None:
        """Test successful daily program update with recalculation of summaries."""
        mock_get_by_id.return_value = self.mock_program
        mock_update.return_value = self.mock_program
        mock_get_community.return_value = None

        data = DailyProgramUpdate(
            items=DailyProgramItemsSchema(
                tasks=[],
                etkinlikler=[],
            )
        )

        response = await update_daily_program_service("prog123", data)

        self.assertEqual(response.id, "prog123")
        mock_get_by_id.assert_called_once_with("prog123")
        mock_update.assert_called_once()

    @patch("app.services.daily_program_service.get_daily_program_by_id", new_callable=AsyncMock)
    async def test_update_daily_program_not_found(self, mock_get_by_id: AsyncMock) -> None:
        """Test updating daily program fails with 404 if program doesn't exist."""
        mock_get_by_id.return_value = None

        with self.assertRaises(HTTPException) as ctx:
            await update_daily_program_service("nonexistent", DailyProgramUpdate())

        self.assertEqual(ctx.exception.status_code, 404)
        self.assertEqual(ctx.exception.detail, PROGRAM_NOT_FOUND)

    @patch("app.services.daily_program_service.get_daily_program_by_id", new_callable=AsyncMock)
    @patch("app.services.daily_program_service.delete_daily_program", new_callable=AsyncMock)
    async def test_delete_daily_program_success(
        self, mock_delete: AsyncMock, mock_get_by_id: AsyncMock
    ) -> None:
        """Test successful daily program deletion."""
        mock_get_by_id.return_value = self.mock_program

        await delete_daily_program_service("prog123")

        mock_get_by_id.assert_called_once_with("prog123")
        mock_delete.assert_called_once_with(self.mock_program)

    @patch("app.services.daily_program_service.get_daily_program_by_id", new_callable=AsyncMock)
    async def test_delete_daily_program_not_found(self, mock_get_by_id: AsyncMock) -> None:
        """Test deletion fails with 404 if program doesn't exist."""
        mock_get_by_id.return_value = None

        with self.assertRaises(HTTPException) as ctx:
            await delete_daily_program_service("nonexistent")

        self.assertEqual(ctx.exception.status_code, 404)
        self.assertEqual(ctx.exception.detail, PROGRAM_NOT_FOUND)


if __name__ == "__main__":
    unittest.main()
