import unittest
from unittest.mock import patch, AsyncMock, MagicMock
from datetime import datetime, date, timezone, timedelta
from fastapi import HTTPException

from app.services.reservation_service import (
    create_reservation_service,
    get_reservation_service,
    list_reservations_by_user_service,
    list_reservations_by_trip_service,
    update_reservation_service,
    delete_reservation_service,
)
from app.schemas.reservation import ReservationCreate, ReservationUpdate
from app.models.user import User, PersonalSettingsModel
from app.core.messages.error_message import (
    RESERVATION_NOT_FOUND,
    RESERVATION_ALREADY_EXISTS,
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


class TestReservationService(unittest.IsolatedAsyncioTestCase):
    """Test suite for Reservation Service."""

    def setUp(self) -> None:
        """Set up standard mock user and mock reservation."""
        # Mock Beanie class attribute details to prevent AttributeError on uninitialized class
        from app.models.reservation import Reservation
        Reservation.details = MagicMock()

        self.mock_user = DummyUser("user123", "owner", "Owner User", "owner@example.com")
        self.mock_other_user = DummyUser("user456", "other", "Other User", "other@example.com")

        # Mock Reservation model
        self.mock_reservation = MagicMock()
        self.mock_reservation.id = "res123"
        self.mock_reservation._id = "res123"
        self.mock_reservation.user_id = "user123"
        self.mock_reservation.community_id = "comm123"
        self.mock_reservation.category = "meeting"
        self.mock_reservation.title = "Test Reservation"
        self.mock_reservation.details = {"pnr": "PNR123"}
        self.mock_reservation.assigned_to = ["user123"]
        self.mock_reservation.is_shared = False
        self.mock_reservation.start_date = datetime.now(timezone.utc)
        self.mock_reservation.end_date = datetime.now(timezone.utc)
        self.mock_reservation.status = "pending"
        self.mock_reservation.location_address = None
        self.mock_reservation.location_lat = None
        self.mock_reservation.location_lng = None
        self.mock_reservation.community_name = None
        
        self.mock_reservation.created_at = datetime.now(timezone.utc)
        self.mock_reservation.updated_at = None
        self.mock_reservation.deleted_at = None
        self.mock_reservation.is_deleted = False
        self.mock_reservation.created_by = None
        self.mock_reservation.updated_by = None
        self.mock_reservation.deleted_by = None

        # Mock Daily Program Model
        self.mock_program = MagicMock()
        self.mock_program.id = "prog123"
        self.mock_program._id = "prog123"
        self.mock_program.items = MagicMock()
        self.mock_program.items.etkinlikler = []
        self.mock_program.ozet = MagicMock()
        self.mock_program.ozet.etkinlik_sayisi = 0
        self.mock_program.save = AsyncMock()

    @patch("app.services.reservation_service.get_community_by_id", new_callable=AsyncMock)
    @patch("app.services.reservation_service.Reservation.find_one", new_callable=AsyncMock)
    @patch("app.services.reservation_service.create_reservation", new_callable=AsyncMock)
    @patch("app.services.reservation_service.get_program_by_user_and_date", new_callable=AsyncMock)
    @patch("app.services.reservation_service.create_daily_program", new_callable=AsyncMock)
    @patch("app.services.notification_service.create_notification_service", new_callable=AsyncMock)
    @patch("app.services.reservation_service.logger", new_callable=AsyncMock)
    async def test_create_reservation_success(
        self,
        mock_logger: AsyncMock,
        mock_create_notif: AsyncMock,
        mock_create_program: AsyncMock,
        mock_get_program: AsyncMock,
        mock_create_res: AsyncMock,
        mock_find_one_pnr: AsyncMock,
        mock_get_community: AsyncMock,
    ) -> None:
        """Test successful reservation creation and program linking."""
        # 1. Mock Community
        mock_comm = MagicMock()
        mock_comm.id = "comm123"
        mock_comm.name = "Test Community"
        mock_comm.owner_id = "user123"
        mock_get_community.return_value = mock_comm

        # 2. Mock PNR lookup returns None (no duplicates)
        mock_find_one_pnr.return_value = None

        # 3. Mock Reservation Creation
        mock_create_res.return_value = self.mock_reservation

        # 4. Mock DailyProgram retrieval and sync
        mock_get_program.return_value = self.mock_program

        data = ReservationCreate(
            community_id="comm123",
            category="meeting",
            title="Test Reservation",
            details={"pnr": "PNR123"},
            status="pending",
            assigned_to=["user123"],
            start_date=datetime.now(timezone.utc),
            end_date=datetime.now(timezone.utc),
        )

        response = await create_reservation_service(self.mock_user, data)

        self.assertEqual(response.id, "res123")
        self.assertEqual(response.community_name, "Test Community")
        mock_get_community.assert_called_once_with("comm123")
        mock_create_res.assert_called_once()
        mock_get_program.assert_called_once()
        self.mock_program.save.assert_called_once()
        mock_logger.info.assert_called_once()

    @patch("app.services.reservation_service.get_community_by_id", new_callable=AsyncMock)
    async def test_create_reservation_unauthorized(self, mock_get_community: AsyncMock) -> None:
        """Test creating reservation by non-owner raises 403."""
        # Community owned by owner (user123)
        mock_comm = MagicMock()
        mock_comm.id = "comm123"
        mock_comm.owner_id = "user123"
        mock_get_community.return_value = mock_comm

        data = ReservationCreate(
            community_id="comm123",
            category="meeting",
            title="Test Reservation",
            details={},
            status="pending",
        )

        with self.assertRaises(HTTPException) as ctx:
            # self.mock_other_user (user456) is NOT the owner
            await create_reservation_service(self.mock_other_user, data)

        self.assertEqual(ctx.exception.status_code, 403)
        self.assertEqual(ctx.exception.detail, UNAUTHORIZED_COMMUNITY_ACTION)

    @patch("app.services.reservation_service.Reservation.find_one", new_callable=AsyncMock)
    async def test_create_reservation_duplicate_pnr(self, mock_find_one_pnr: AsyncMock) -> None:
        """Test creating reservation with existing PNR raises 409."""
        mock_find_one_pnr.return_value = self.mock_reservation

        data = ReservationCreate(
            category="meeting",
            title="Test Reservation",
            details={"pnr": "PNR123"},
            status="pending",
        )

        with self.assertRaises(HTTPException) as ctx:
            await create_reservation_service(self.mock_user, data)

        self.assertEqual(ctx.exception.status_code, 409)
        self.assertEqual(ctx.exception.detail, RESERVATION_ALREADY_EXISTS)

    @patch("app.services.reservation_service.get_reservation_by_id", new_callable=AsyncMock)
    @patch("app.services.reservation_service.get_community_by_id", new_callable=AsyncMock)
    async def test_get_reservation_success(
        self, mock_get_community: AsyncMock, mock_get_by_id: AsyncMock
    ) -> None:
        """Test successful reservation retrieval by ID."""
        mock_get_by_id.return_value = self.mock_reservation
        
        mock_comm = MagicMock()
        mock_comm.name = "Test Community"
        mock_get_community.return_value = mock_comm

        response = await get_reservation_service("res123")

        self.assertEqual(response.id, "res123")
        self.assertEqual(response.community_name, "Test Community")
        mock_get_by_id.assert_called_once_with("res123")
        mock_get_community.assert_called_once_with("comm123")

    @patch("app.services.reservation_service.get_reservation_by_id", new_callable=AsyncMock)
    async def test_get_reservation_not_found(self, mock_get_by_id: AsyncMock) -> None:
        """Test retrieving non-existent reservation raises 404."""
        mock_get_by_id.return_value = None

        with self.assertRaises(HTTPException) as ctx:
            await get_reservation_service("nonexistent")

        self.assertEqual(ctx.exception.status_code, 404)
        self.assertEqual(ctx.exception.detail, RESERVATION_NOT_FOUND)

    @patch("app.services.reservation_service.get_reservation_by_user_id", new_callable=AsyncMock)
    @patch("app.services.reservation_service.get_community_by_id", new_callable=AsyncMock)
    async def test_list_reservations_by_user_success(
        self, mock_get_community: AsyncMock, mock_get_by_user: AsyncMock
    ) -> None:
        """Test listing reservations for a user."""
        mock_get_by_user.return_value = [self.mock_reservation]
        mock_get_community.return_value = None

        response = await list_reservations_by_user_service("user123")

        self.assertEqual(len(response), 1)
        self.assertEqual(response[0].id, "res123")
        mock_get_by_user.assert_called_once_with("user123")

    @patch("app.services.reservation_service.get_reservation_by_trip_id", new_callable=AsyncMock)
    async def test_list_reservations_by_trip_success(self, mock_get_by_trip: AsyncMock) -> None:
        """Test listing reservations for a trip."""
        mock_get_by_trip.return_value = [self.mock_reservation]

        response = await list_reservations_by_trip_service("trip123")

        self.assertEqual(len(response), 1)
        self.assertEqual(response[0].id, "res123")
        mock_get_by_trip.assert_called_once_with("trip123")

    @patch("app.services.reservation_service.get_reservation_by_id", new_callable=AsyncMock)
    @patch("app.services.reservation_service.update_reservation", new_callable=AsyncMock)
    @patch("app.services.reservation_service.logger", new_callable=AsyncMock)
    async def test_update_reservation_success(
        self, mock_logger: AsyncMock, mock_update: AsyncMock, mock_get_by_id: AsyncMock
    ) -> None:
        """Test successful reservation update."""
        mock_get_by_id.return_value = self.mock_reservation
        mock_update.return_value = self.mock_reservation

        data = ReservationUpdate(title="New Title")
        response = await update_reservation_service("res123", data)

        self.assertEqual(response.id, "res123")
        mock_get_by_id.assert_called_once_with("res123")
        mock_update.assert_called_once()
        mock_logger.info.assert_called_once()

    @patch("app.services.reservation_service.get_reservation_by_id", new_callable=AsyncMock)
    @patch("app.services.reservation_service.get_program_by_user_and_date", new_callable=AsyncMock)
    @patch("app.services.reservation_service.delete_reservation", new_callable=AsyncMock)
    @patch("app.services.reservation_service.logger", new_callable=AsyncMock)
    async def test_delete_reservation_by_creator_success(
        self,
        mock_logger: AsyncMock,
        mock_delete: AsyncMock,
        mock_get_program: AsyncMock,
        mock_get_by_id: AsyncMock,
    ) -> None:
        """Test successful reservation deletion by its creator (cleans up all programs)."""
        mock_get_by_id.return_value = self.mock_reservation
        
        # Mock program containing the reservation
        mock_program = MagicMock()
        mock_program.items = MagicMock()
        mock_program.items.etkinlikler = [self.mock_reservation]
        mock_program.ozet = MagicMock()
        mock_program.ozet.etkinlik_sayisi = 1
        mock_program.save = AsyncMock()

        mock_get_program.return_value = mock_program

        # self.mock_user is the creator (user123)
        await delete_reservation_service("res123", self.mock_user)

        mock_get_by_id.assert_called_once_with("res123")
        mock_delete.assert_called_once_with(self.mock_reservation)
        mock_get_program.assert_called_once()
        mock_program.save.assert_called_once()
        mock_logger.warning.assert_called_once()

    @patch("app.services.reservation_service.get_reservation_by_id", new_callable=AsyncMock)
    @patch("app.services.reservation_service.get_program_by_user_and_date", new_callable=AsyncMock)
    @patch("app.services.reservation_service.logger", new_callable=AsyncMock)
    async def test_delete_reservation_by_assigned_only_success(
        self,
        mock_logger: AsyncMock,
        mock_get_program: AsyncMock,
        mock_get_by_id: AsyncMock,
    ) -> None:
        """Test successful reservation removal from own program by an assigned non-creator user."""
        # user123 is creator, but user456 is assigned too
        self.mock_reservation.assigned_to = ["user123", "user456"]
        mock_get_by_id.return_value = self.mock_reservation
        self.mock_reservation.save = AsyncMock()

        mock_program = MagicMock()
        mock_program.items = MagicMock()
        mock_program.items.etkinlikler = [self.mock_reservation]
        mock_program.ozet = MagicMock()
        mock_program.ozet.etkinlik_sayisi = 1
        mock_program.save = AsyncMock()

        mock_get_program.return_value = mock_program

        # self.mock_other_user (user456) is NOT the creator
        await delete_reservation_service("res123", self.mock_other_user)

        mock_get_by_id.assert_called_once_with("res123")
        mock_get_program.assert_called_once()
        mock_program.save.assert_called_once()
        self.mock_reservation.save.assert_called_once()
        self.assertNotIn("user456", self.mock_reservation.assigned_to)
        mock_logger.info.assert_called_once()


if __name__ == "__main__":
    unittest.main()
