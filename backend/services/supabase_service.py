# NEW FILE — Supabase Database Service
# Handles all CRUD operations for Supabase tables

from supabase import create_client, Client
from config import get_config
from utils.logger import get_logger
from utils.retry import retry_on_failure
from datetime import datetime, date

logger = get_logger(__name__)

import threading

_supabase_client: Client = None
_client_lock = threading.Lock()


def get_supabase() -> Client:
    """Get or create Supabase client (singleton)."""
    global _supabase_client
    with _client_lock:
        if _supabase_client is None:
            config = get_config()
            _supabase_client = create_client(
                config.SUPABASE_URL,
                config.SUPABASE_SERVICE_ROLE_KEY  # Service role for backend operations
            )
            logger.info("Supabase client initialized.")
        return _supabase_client


# ============================================================
# USER OPERATIONS
# ============================================================

@retry_on_failure(max_retries=3)
def create_user(user_data: dict) -> dict:
    """Create or update a user in the users table."""
    sb = get_supabase()
    try:
        result = sb.table("users").upsert({
            "id": user_data["uid"],
            "name": user_data.get("name", ""),
            "email": user_data.get("email", ""),
            "role": user_data.get("role", "citizen"),
            "phone": user_data.get("phone"),
            "avatar_url": user_data.get("avatar_url"),
            "fcm_token": user_data.get("fcm_token"),
        }).execute()
        logger.info(f"User upserted: {user_data['uid']}")
        return result.data[0] if result.data else None
    except Exception as e:
        logger.error(f"Error creating user: {e}")
        raise


@retry_on_failure(max_retries=3)
def get_user(user_id: str) -> dict:
    """Get user by Firebase UID."""
    sb = get_supabase()
    try:
        result = sb.table("users").select("*").eq("id", user_id).execute()
        return result.data[0] if result.data else None
    except Exception as e:
        logger.error(f"Error fetching user {user_id}: {e}")
        raise


@retry_on_failure(max_retries=3)
def update_user(user_id: str, updates: dict) -> dict:
    """Update user profile."""
    sb = get_supabase()
    try:
        result = sb.table("users").update(updates).eq("id", user_id).execute()
        return result.data[0] if result.data else None
    except Exception as e:
        logger.error(f"Error updating user {user_id}: {e}")
        raise


# ============================================================
# REPORT OPERATIONS
# ============================================================

@retry_on_failure(max_retries=3)
def create_report(report_data: dict) -> dict:
    """Create a new report."""
    sb = get_supabase()
    try:
        result = sb.table("reports").insert({
            "user_id": report_data["user_id"],
            "category": report_data["category"],
            "description": report_data.get("description", ""),
            "image_url": report_data.get("image_url"),
            "latitude": report_data["latitude"],
            "longitude": report_data["longitude"],
            "address": report_data.get("address"),
            "status": "pending",
            "ai_detection_result": report_data.get("ai_detection_result"),
        }).execute()
        logger.info(f"Report created by user: {report_data['user_id']}")
        return result.data[0] if result.data else None
    except Exception as e:
        logger.error(f"Error creating report: {e}")
        raise


@retry_on_failure(max_retries=3)
def get_reports(filters: dict = None, limit: int = 50, offset: int = 0) -> list:
    """Get reports with optional filters."""
    sb = get_supabase()
    try:
        query = sb.table("reports").select("*, users!reports_user_id_fkey(name, email)")

        if filters:
            if filters.get("user_id"):
                query = query.eq("user_id", filters["user_id"])
            if filters.get("status"):
                query = query.eq("status", filters["status"])
            if filters.get("category"):
                query = query.eq("category", filters["category"])
            if filters.get("assigned_worker_id"):
                query = query.eq("assigned_worker_id", filters["assigned_worker_id"])

        result = query.order("created_at", desc=True).range(offset, offset + limit - 1).execute()
        return result.data or []
    except Exception as e:
        logger.error(f"Error fetching reports: {e}")
        raise


@retry_on_failure(max_retries=3)
def get_report_by_id(report_id: str) -> dict:
    """Get a single report by ID."""
    sb = get_supabase()
    try:
        result = sb.table("reports").select(
            "*, users!reports_user_id_fkey(name, email)"
        ).eq("id", report_id).execute()
        return result.data[0] if result.data else None
    except Exception as e:
        logger.error(f"Error fetching report {report_id}: {e}")
        raise


@retry_on_failure(max_retries=3)
def update_report(report_id: str, updates: dict) -> dict:
    """Update a report."""
    sb = get_supabase()
    try:
        result = sb.table("reports").update(updates).eq("id", report_id).execute()
        return result.data[0] if result.data else None
    except Exception as e:
        logger.error(f"Error updating report {report_id}: {e}")
        raise


@retry_on_failure(max_retries=3)
def assign_worker_to_report(report_id: str, worker_id: str) -> dict:
    """Assign a worker to a report."""
    sb = get_supabase()
    try:
        result = sb.table("reports").update({
            "assigned_worker_id": worker_id,
            "status": "assigned",
        }).eq("id", report_id).execute()
        logger.info(f"Worker {worker_id} assigned to report {report_id}")
        return result.data[0] if result.data else None
    except Exception as e:
        logger.error(f"Error assigning worker: {e}")
        raise


@retry_on_failure(max_retries=3)
def complete_report(report_id: str, completion_data: dict) -> dict:
    """Mark a report as completed with proof."""
    sb = get_supabase()
    try:
        result = sb.table("reports").update({
            "status": "completed",
            "completion_image_url": completion_data.get("completion_image_url"),
            "completion_remarks": completion_data.get("remarks"),
            "completed_at": datetime.utcnow().isoformat(),
        }).eq("id", report_id).execute()
        logger.info(f"Report {report_id} marked as completed")
        return result.data[0] if result.data else None
    except Exception as e:
        logger.error(f"Error completing report: {e}")
        raise


def get_report_stats() -> dict:
    """Get report statistics for admin dashboard."""
    sb = get_supabase()
    try:
        all_reports = sb.table("reports").select("id, status, category, created_at").execute()
        data = all_reports.data or []

        total = len(data)
        pending = sum(1 for r in data if r["status"] == "pending")
        assigned = sum(1 for r in data if r["status"] == "assigned")
        in_progress = sum(1 for r in data if r["status"] == "in_progress")
        completed = sum(1 for r in data if r["status"] == "completed")

        # Category distribution
        categories = {}
        for r in data:
            cat = r["category"]
            categories[cat] = categories.get(cat, 0) + 1

        # Hourly distribution (last 24h)
        hourly = {}
        for r in data:
            hour = r["created_at"][:13]  # YYYY-MM-DDTHH
            hourly[hour] = hourly.get(hour, 0) + 1

        return {
            "total": total,
            "pending": pending,
            "assigned": assigned,
            "in_progress": in_progress,
            "completed": completed,
            "active": pending + assigned + in_progress,
            "categories": categories,
            "hourly": hourly,
        }
    except Exception as e:
        logger.error(f"Error fetching report stats: {e}")
        raise


# ============================================================
# WORKER OPERATIONS
# ============================================================

@retry_on_failure(max_retries=3)
def create_worker(worker_data: dict) -> dict:
    """Create a worker record."""
    sb = get_supabase()
    try:
        result = sb.table("workers").insert({
            "worker_id": worker_data["worker_id"],
            "name": worker_data["name"],
            "phone": worker_data.get("phone"),
            "status": "available",
        }).execute()
        logger.info(f"Worker created: {worker_data['worker_id']}")
        return result.data[0] if result.data else None
    except Exception as e:
        logger.error(f"Error creating worker: {e}")
        raise


@retry_on_failure(max_retries=3)
def get_workers(status: str = None) -> list:
    """Get all workers, optionally filtered by status."""
    sb = get_supabase()
    try:
        query = sb.table("workers").select("*")
        if status:
            query = query.eq("status", status)
        result = query.execute()
        return result.data or []
    except Exception as e:
        logger.error(f"Error fetching workers: {e}")
        raise


@retry_on_failure(max_retries=3)
def get_worker(worker_id: str) -> dict:
    """Get a specific worker."""
    sb = get_supabase()
    try:
        result = sb.table("workers").select("*").eq("worker_id", worker_id).execute()
        return result.data[0] if result.data else None
    except Exception as e:
        logger.error(f"Error fetching worker {worker_id}: {e}")
        raise


@retry_on_failure(max_retries=3)
def update_worker(worker_id: str, updates: dict) -> dict:
    """Update worker record."""
    sb = get_supabase()
    try:
        result = sb.table("workers").update(updates).eq("worker_id", worker_id).execute()
        return result.data[0] if result.data else None
    except Exception as e:
        logger.error(f"Error updating worker {worker_id}: {e}")
        raise


# ============================================================
# ATTENDANCE OPERATIONS
# ============================================================

@retry_on_failure(max_retries=3)
def record_login(attendance_data: dict) -> dict:
    """Record worker login attendance."""
    sb = get_supabase()
    try:
        today = date.today().isoformat()
        result = sb.table("attendance").upsert({
            "worker_id": attendance_data["worker_id"],
            "login_time": datetime.utcnow().isoformat(),
            "login_photo": attendance_data.get("login_photo"),
            "latitude": attendance_data.get("latitude"),
            "longitude": attendance_data.get("longitude"),
            "date": today,
        }).execute()
        logger.info(f"Login recorded for worker: {attendance_data['worker_id']}")
        return result.data[0] if result.data else None
    except Exception as e:
        logger.error(f"Error recording login: {e}")
        raise


@retry_on_failure(max_retries=3)
def record_logout(attendance_data: dict) -> dict:
    """Record worker logout attendance."""
    sb = get_supabase()
    try:
        today = date.today().isoformat()
        result = sb.table("attendance").update({
            "logout_time": datetime.utcnow().isoformat(),
            "logout_photo": attendance_data.get("logout_photo"),
        }).eq("worker_id", attendance_data["worker_id"]).eq("date", today).execute()
        logger.info(f"Logout recorded for worker: {attendance_data['worker_id']}")
        return result.data[0] if result.data else None
    except Exception as e:
        logger.error(f"Error recording logout: {e}")
        raise


@retry_on_failure(max_retries=3)
def get_attendance(worker_id: str = None, limit: int = 30) -> list:
    """Get attendance records."""
    sb = get_supabase()
    try:
        query = sb.table("attendance").select("*")
        if worker_id:
            query = query.eq("worker_id", worker_id)
        result = query.order("date", desc=True).limit(limit).execute()
        return result.data or []
    except Exception as e:
        logger.error(f"Error fetching attendance: {e}")
        raise


# ============================================================
# SUPPORT TICKET OPERATIONS
# ============================================================

@retry_on_failure(max_retries=3)
def create_support_ticket(ticket_data: dict) -> dict:
    """Create a support ticket."""
    sb = get_supabase()
    try:
        result = sb.table("support_tickets").insert({
            "user_id": ticket_data["user_id"],
            "message": ticket_data["message"],
            "status": "open",
        }).execute()
        logger.info(f"Support ticket created by user: {ticket_data['user_id']}")
        return result.data[0] if result.data else None
    except Exception as e:
        logger.error(f"Error creating support ticket: {e}")
        raise


@retry_on_failure(max_retries=3)
def get_support_tickets(user_id: str = None, status: str = None) -> list:
    """Get support tickets with optional filters."""
    sb = get_supabase()
    try:
        query = sb.table("support_tickets").select("*, users!support_tickets_user_id_fkey(name, email)")
        if user_id:
            query = query.eq("user_id", user_id)
        if status:
            query = query.eq("status", status)
        result = query.order("created_at", desc=True).execute()
        return result.data or []
    except Exception as e:
        logger.error(f"Error fetching support tickets: {e}")
        raise


@retry_on_failure(max_retries=3)
def respond_to_ticket(ticket_id: str, response: str, admin_id: str) -> dict:
    """Admin responds to a support ticket."""
    sb = get_supabase()
    try:
        result = sb.table("support_tickets").update({
            "response": response,
            "responded_by": admin_id,
            "status": "resolved",
        }).eq("id", ticket_id).execute()
        logger.info(f"Ticket {ticket_id} responded by admin {admin_id}")
        return result.data[0] if result.data else None
    except Exception as e:
        logger.error(f"Error responding to ticket: {e}")
        raise


# ============================================================
# NOTIFICATION OPERATIONS
# ============================================================

@retry_on_failure(max_retries=3)
def create_notification(notif_data: dict) -> dict:
    """Create a notification for a user."""
    sb = get_supabase()
    try:
        result = sb.table("notifications").insert({
            "user_id": notif_data["user_id"],
            "title": notif_data["title"],
            "body": notif_data["body"],
            "type": notif_data["type"],
            "report_id": notif_data.get("report_id"),
        }).execute()
        return result.data[0] if result.data else None
    except Exception as e:
        logger.error(f"Error creating notification: {e}")
        raise


@retry_on_failure(max_retries=3)
def get_notifications(user_id: str, unread_only: bool = False) -> list:
    """Get notifications for a user."""
    sb = get_supabase()
    try:
        query = sb.table("notifications").select("*").eq("user_id", user_id)
        if unread_only:
            query = query.eq("is_read", False)
        result = query.order("created_at", desc=True).limit(50).execute()
        return result.data or []
    except Exception as e:
        logger.error(f"Error fetching notifications: {e}")
        raise


@retry_on_failure(max_retries=3)
def mark_notification_read(notification_id: str) -> dict:
    """Mark a notification as read."""
    sb = get_supabase()
    try:
        result = sb.table("notifications").update({
            "is_read": True,
        }).eq("id", notification_id).execute()
        return result.data[0] if result.data else None
    except Exception as e:
        logger.error(f"Error marking notification read: {e}")
        raise


# ============================================================
# IMAGE UPLOAD (via Supabase Storage)
# ============================================================

def upload_image(bucket: str, file_path: str, file_data: bytes) -> str:
    """Upload image to Supabase Storage and return public URL."""
    sb = get_supabase()
    try:
        result = sb.storage.from_(bucket).upload(file_path, file_data)
        public_url = sb.storage.from_(bucket).get_public_url(file_path)
        logger.info(f"Image uploaded to {bucket}/{file_path}")
        return public_url
    except Exception as e:
        logger.error(f"Error uploading image: {e}")
        raise
