# NEW FILE — Push Notification Service
# Sends Firebase Cloud Messaging notifications

import requests
import json
from config import get_config
from utils.logger import get_logger
from utils.retry import retry_on_failure

logger = get_logger(__name__)

FCM_SEND_URL = "https://fcm.googleapis.com/fcm/send"


@retry_on_failure(max_retries=3)
def send_push_notification(fcm_token: str, title: str, body: str, data: dict = None) -> bool:
    """
    Send a push notification via Firebase Cloud Messaging.

    Args:
        fcm_token: Device FCM token
        title: Notification title
        body: Notification body text
        data: Optional data payload

    Returns:
        bool: True if sent successfully
    """
    config = get_config()
    server_key = config.FCM_SERVER_KEY

    if not server_key:
        logger.warning("FCM server key not configured. Skipping push notification.")
        return False

    headers = {
        "Authorization": f"key={server_key}",
        "Content-Type": "application/json",
    }

    payload = {
        "to": fcm_token,
        "notification": {
            "title": title,
            "body": body,
            "sound": "default",
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
        },
        "data": data or {},
        "priority": "high",
    }

    try:
        response = requests.post(FCM_SEND_URL, headers=headers, json=payload, timeout=10)
        response.raise_for_status()

        result = response.json()
        if result.get("success", 0) > 0:
            logger.info(f"Push notification sent: {title}")
            return True
        else:
            logger.warning(f"Push notification failed: {result}")
            return False
    except Exception as e:
        logger.error(f"Error sending push notification: {e}")
        raise


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
