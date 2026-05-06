import asyncio
from datetime import datetime, timedelta
from app.core.logger import logger
from app.models.task import Task
from app.models.reservation import Reservation
from app.models.notification import NotificationType
from app.services.notification_service import create_notification_service

async def check_upcoming_reminders():
    """
    Background worker that checks for upcoming tasks and reservations
    and sends push notifications based on category-specific rules.
    """
    try:
        now = datetime.utcnow()
        # Fetch unsent records starting in the next 4 hours (covers the max 3h rule)
        lookahead = now + timedelta(hours=4)

        # 1. Process Tasks
        tasks = await Task.find(
            Task.reminder_sent == False,
            Task.start_date <= lookahead,
            Task.start_date != None
        ).to_list()

        for task in tasks:
            lead_time = timedelta(minutes=30)  # Default
            if task.type and "spor" in task.type.lower():
                lead_time = timedelta(hours=1)
            elif task.type and "toplantı" in task.type.lower():
                lead_time = timedelta(minutes=30)
            
            # If start_date is within lead_time from now, send notification
            if task.start_date <= now + lead_time:
                # Determine user_id (tasks might have multiple assigned_to or a creator_id)
                # For simplicity, we notify everyone assigned
                targets = task.assigned_to if task.assigned_to else [task.creator_id]
                
                for user_id in targets:
                    try:
                        await create_notification_service(
                            user_id=user_id,
                            type=NotificationType.GENERAL,
                            title=f"Hatırlatma: {task.title}",
                            body=f"'{task.title}' görevin yaklaşıyor! ({task.start_date.strftime('%H:%M')})",
                            metadata={"task_id": task.id}
                        )
                    except Exception as e:
                        logger.error(f"Failed to send task reminder to {user_id}: {e}")

                task.reminder_sent = True
                await task.save()

        # 2. Process Reservations
        reservations = await Reservation.find(
            Reservation.reminder_sent == False,
            Reservation.start_date <= lookahead,
            Reservation.start_date != None
        ).to_list()

        for res in reservations:
            # Rule: Reservations and Tickets are 3 hours before
            lead_time = timedelta(hours=3)
            
            if res.start_date <= now + lead_time:
                # Notify owner and anyone assigned
                targets = list(set([res.user_id] + res.assigned_to))
                
                for user_id in targets:
                    try:
                        await create_notification_service(
                            user_id=user_id,
                            type=NotificationType.GENERAL,
                            title=f"Hatırlatma: {res.title}",
                            body=f"'{res.title}' rezervasyonun/biletin yaklaşıyor! ({res.start_date.strftime('%H:%M')})",
                            metadata={"reservation_id": res.id}
                        )
                    except Exception as e:
                        logger.error(f"Failed to send reservation reminder to {user_id}: {e}")

                res.reminder_sent = True
                await res.save()

    except Exception as e:
        logger.error(f"Error in reminder_service loop: {e}")

async def start_reminder_worker():
    """Starts the infinite loop for checking reminders every minute."""
    logger.info("Starting reminder background worker...")
    while True:
        await check_upcoming_reminders()
        await asyncio.sleep(60) # Run every minute
