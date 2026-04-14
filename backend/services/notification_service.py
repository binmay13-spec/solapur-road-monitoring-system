# NEW FILE — Push Notification Service
# Sends Firebase Cloud Messaging notifications

import requests
import json
from config import get_config
from utils.logger import get_logger
from utils.retry import retry_on_failure

logger = get_logger(__name__)

from firebase_admin import messaging
from .firebase_auth_service import initialize_firebase

@retry_on_failure(max_retries=3)
def send_push_notification(fcm_token: str, title: str, body: str, data: dict = None) -> bool:
    """
    Send a push notification via Firebase Cloud Messaging (FCM v1).
    """
    initialize_firebase()

    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        data=data or {},
        token=fcm_token,
        android=messaging.AndroidConfig(
            priority="high",
            notification=messaging.AndroidNotification(
                click_action="FLUTTER_NOTIFICATION_CLICK",
                sound="default",
            ),
        ),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(sound="default"),
            ),
        ),
    )

    try:
        response = messaging.send(message)
        logger.info(f"Push notification sent successfully: {response}")
        return True
    except Exception as e:
        logger.error(f"Error sending push notification via FCM v1: {e}")
        return False


def notify_worker_assigned(user_fcm_token: str, report_id: str, worker_name: str):
    """Notify citizen when a worker is assigned to their report."""
    send_push_notification(
        fcm_token=user_fcm_token,
        title="Worker Assigned",
        body=f"{worker_name} has been assigned to your reported issue.",
        data={"type": "assignment", "report_id": report_id},
    )


def notify_work_started(user_fcm_token: str, report_id: str):
    """Notify citizen when work starts on their issue."""
    send_push_notification(
        fcm_token=user_fcm_token,
        title="Work Started",
        body="A worker has started resolving your reported issue.",
        data={"type": "status_update", "report_id": report_id},
    )


def notify_issue_resolved(user_fcm_token: str, report_id: str):
    """Notify citizen when their issue is resolved."""
    send_push_notification(
        fcm_token=user_fcm_token,
        title="Issue Resolved ✅",
        body="Your reported issue has been resolved! Thank you for helping.",
        data={"type": "completion", "report_id": report_id},
    )
