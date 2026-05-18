import unittest
from unittest.mock import patch, AsyncMock, MagicMock
from datetime import datetime, timedelta

from app.services.reminder_service import (
    check_upcoming_reminders,
    start_reminder_worker,
)
from app.models.notification import NotificationType


class TestReminderService(unittest.IsolatedAsyncioTestCase):
    """Test suite for Reminder Service background worker."""

    def setUp(self) -> None:
        """Set up standard helper variables."""
        pass

    @patch("app.services.reminder_service.Task")
    @patch("app.services.reminder_service.Reservation")
    @patch("app.services.reminder_service.create_notification_service", new_callable=AsyncMock)
    @patch("app.services.reminder_service.logger")
    async def test_check_upcoming_reminders_task_sent(
        self,
        mock_logger: MagicMock,
        mock_create_notification: AsyncMock,
        mock_reservation_class: MagicMock,
        mock_task_class: MagicMock,
    ) -> None:
        """Test task reminder is sent for upcoming tasks."""
        # Prevent TypeError on Mock comparisons in Task/Reservation Beanie query filters
        mock_task_class.reminder_sent.__eq__.return_value = True
        mock_task_class.start_date.__le__.return_value = True
        mock_task_class.start_date.__ne__.return_value = True

        mock_reservation_class.reminder_sent.__eq__.return_value = True
        mock_reservation_class.start_date.__le__.return_value = True
        mock_reservation_class.start_date.__ne__.return_value = True

        # 1. Setup mock task
        mock_task = MagicMock()
        mock_task.id = "task123"
        mock_task.title = "Sport Task"
        mock_task.type = "Spor"
        mock_task.start_date = datetime.utcnow() + timedelta(minutes=40)  # within 1h lead time
        mock_task.assigned_to = ["user123"]
        mock_task.creator_id = "creator123"
        mock_task.reminder_sent = False
        mock_task.save = AsyncMock()

        # Chain Beanie find() -> to_list()
        mock_task_find = MagicMock()
        mock_task_find.to_list = AsyncMock(return_value=[mock_task])
        mock_task_class.find.return_value = mock_task_find

        # Empty reservations list
        mock_res_find = MagicMock()
        mock_res_find.to_list = AsyncMock(return_value=[])
        mock_reservation_class.find.return_value = mock_res_find

        await check_upcoming_reminders()

        # Assertions
        mock_create_notification.assert_called_once_with(
            user_id="user123",
            type=NotificationType.GENERAL,
            title="Hatırlatma: Sport Task",
            body="'Sport Task' görevin yaklaşıyor! (" + mock_task.start_date.strftime('%H:%M') + ")",
            metadata={"task_id": "task123"},
        )
        self.assertTrue(mock_task.reminder_sent)
        mock_task.save.assert_called_once()

    @patch("app.services.reminder_service.Task")
    @patch("app.services.reminder_service.Reservation")
    @patch("app.services.reminder_service.create_notification_service", new_callable=AsyncMock)
    @patch("app.services.reminder_service.logger")
    async def test_check_upcoming_reminders_task_not_yet(
        self,
        mock_logger: MagicMock,
        mock_create_notification: AsyncMock,
        mock_reservation_class: MagicMock,
        mock_task_class: MagicMock,
    ) -> None:
        """Test task reminder is NOT sent if start time is too far in future."""
        # Prevent TypeError on Mock comparisons
        mock_task_class.reminder_sent.__eq__.return_value = True
        mock_task_class.start_date.__le__.return_value = True
        mock_task_class.start_date.__ne__.return_value = True

        mock_reservation_class.reminder_sent.__eq__.return_value = True
        mock_reservation_class.start_date.__le__.return_value = True
        mock_reservation_class.start_date.__ne__.return_value = True

        # Setup mock task starting in 2 hours (default lead is 30m, sport lead is 1h)
        mock_task = MagicMock()
        mock_task.id = "task123"
        mock_task.title = "Far Meeting"
        mock_task.type = "Toplantı"
        mock_task.start_date = datetime.utcnow() + timedelta(hours=2)
        mock_task.assigned_to = []
        mock_task.creator_id = "creator123"
        mock_task.reminder_sent = False
        mock_task.save = AsyncMock()

        mock_task_find = MagicMock()
        mock_task_find.to_list = AsyncMock(return_value=[mock_task])
        mock_task_class.find.return_value = mock_task_find

        # Empty reservations
        mock_res_find = MagicMock()
        mock_res_find.to_list = AsyncMock(return_value=[])
        mock_reservation_class.find.return_value = mock_res_find

        await check_upcoming_reminders()

        mock_create_notification.assert_not_called()
        self.assertFalse(mock_task.reminder_sent)
        mock_task.save.assert_not_called()

    @patch("app.services.reminder_service.Task")
    @patch("app.services.reminder_service.Reservation")
    @patch("app.services.reminder_service.create_notification_service", new_callable=AsyncMock)
    @patch("app.services.reminder_service.logger")
    async def test_check_upcoming_reminders_reservation_sent(
        self,
        mock_logger: MagicMock,
        mock_create_notification: AsyncMock,
        mock_reservation_class: MagicMock,
        mock_task_class: MagicMock,
    ) -> None:
        """Test reservation reminder is sent for upcoming reservations."""
        # Prevent TypeError on Mock comparisons
        mock_task_class.reminder_sent.__eq__.return_value = True
        mock_task_class.start_date.__le__.return_value = True
        mock_task_class.start_date.__ne__.return_value = True

        mock_reservation_class.reminder_sent.__eq__.return_value = True
        mock_reservation_class.start_date.__le__.return_value = True
        mock_reservation_class.start_date.__ne__.return_value = True

        # Empty tasks list
        mock_task_find = MagicMock()
        mock_task_find.to_list = AsyncMock(return_value=[])
        mock_task_class.find.return_value = mock_task_find

        # Setup mock reservation
        mock_res = MagicMock()
        mock_res.id = "res123"
        mock_res.title = "Ticket Reservation"
        mock_res.start_date = datetime.utcnow() + timedelta(hours=2)  # within 3h lead time
        mock_res.user_id = "user123"
        mock_res.assigned_to = ["user456"]
        mock_res.reminder_sent = False
        mock_res.save = AsyncMock()

        mock_res_find = MagicMock()
        mock_res_find.to_list = AsyncMock(return_value=[mock_res])
        mock_reservation_class.find.return_value = mock_res_find

        await check_upcoming_reminders()

        # Targets include both owner and assigned users (unique list)
        self.assertEqual(mock_create_notification.call_count, 2)
        self.assertTrue(mock_res.reminder_sent)
        mock_res.save.assert_called_once()

    @patch("app.services.reminder_service.Task")
    @patch("app.services.reminder_service.logger")
    async def test_check_upcoming_reminders_exception_logged(
        self, mock_logger: MagicMock, mock_task_class: MagicMock
    ) -> None:
        """Test that exceptions raised are caught and logged, not crashed."""
        mock_task_class.find.side_effect = Exception("Database error")
        mock_logger.error = AsyncMock()

        # Should not raise exception
        await check_upcoming_reminders()

        mock_logger.error.assert_called_once()

    @patch("app.services.reminder_service.check_upcoming_reminders", new_callable=AsyncMock)
    @patch("app.services.reminder_service.asyncio.sleep", new_callable=AsyncMock)
    @patch("app.services.reminder_service.logger")
    async def test_start_reminder_worker(
        self, mock_logger: MagicMock, mock_sleep: AsyncMock, mock_check: AsyncMock
    ) -> None:
        """Test start_reminder_worker executes check_upcoming_reminders and sleeps in loop."""
        mock_logger.info = MagicMock()
        # Cause asyncio.sleep to raise exception to break infinite loop
        mock_sleep.side_effect = KeyboardInterrupt("Break loop")

        with self.assertRaises(KeyboardInterrupt):
            await start_reminder_worker()

        mock_check.assert_called_once()
        mock_sleep.assert_called_once_with(60)


if __name__ == "__main__":
    unittest.main()
