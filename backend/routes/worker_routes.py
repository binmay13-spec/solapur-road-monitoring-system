# NEW FILE — Worker Routes
# Handles worker tasks, attendance, and task completion

import base64
import uuid
from flask import Blueprint, request, jsonify, g
from services.supabase_service import (
    get_reports, get_report_by_id, update_report, complete_report,
    record_login, record_logout, get_attendance,
    get_workers, get_worker, create_worker, update_worker,
    get_user, create_notification, upload_image,
)
from services.notification_service import notify_work_started, notify_issue_resolved
from middleware.auth_middleware import token_required, worker_required, admin_required
from utils.logger import get_logger

logger = get_logger(__name__)

worker_bp = Blueprint("worker", __name__)


# ============================================================
# TASK MANAGEMENT
# ============================================================

@worker_bp.route("/worker/tasks", methods=["GET"])
@token_required
@worker_required
def get_worker_tasks():
    """
    Get tasks assigned to the current worker.

    Query params:
        - status: filter by status (assigned, in_progress, completed)
    """
    try:
        filters = {"assigned_worker_id": g.firebase_uid}

        status = request.args.get("status")
        if status:
            filters["status"] = status

        tasks = get_reports(filters=filters, limit=100)

        # Group by status
        assigned = [t for t in tasks if t["status"] == "assigned"]
        in_progress = [t for t in tasks if t["status"] == "in_progress"]
        completed = [t for t in tasks if t["status"] == "completed"]

        return jsonify({
            "success": True,
            "tasks": tasks,
            "summary": {
                "assigned": len(assigned),
                "in_progress": len(in_progress),
                "completed": len(completed),
                "total": len(tasks),
            },
        }), 200

    except Exception as e:
        logger.error(f"Error fetching worker tasks: {e}")
        return jsonify({"success": False, "error": "Failed to fetch tasks"}), 500


@worker_bp.route("/worker/tasks/<task_id>/start", methods=["PUT"])
@token_required
@worker_required
def start_task(task_id):
    """Mark a task as in_progress."""
    try:
        report = get_report_by_id(task_id)
        if not report:
            return jsonify({"success": False, "error": "Task not found"}), 404

        if report.get("assigned_worker_id") != g.firebase_uid:
            return jsonify({"success": False, "error": "Task not assigned to you"}), 403

        updated = update_report(task_id, {"status": "in_progress"})

        # Notify citizen
        citizen = get_user(report["user_id"])
        if citizen and citizen.get("fcm_token"):
            try:
                notify_work_started(citizen["fcm_token"], task_id)
            except Exception:
                pass

        create_notification({
            "user_id": report["user_id"],
            "title": "Work Started",
            "body": "A worker has started working on your reported issue.",
            "type": "status_update",
            "report_id": task_id,
        })

        return jsonify({
            "success": True,
            "message": "Task started",
            "task": updated,
        }), 200

    except Exception as e:
        logger.error(f"Error starting task: {e}")
        return jsonify({"success": False, "error": "Failed to start task"}), 500


@worker_bp.route("/worker/tasks/<task_id>/complete", methods=["PUT"])
@token_required
@worker_required
def complete_task(task_id):
    """
    Complete a task with proof.

    Request (form data or JSON):
        - remarks: completion notes
        - image: proof photo file
        - image_base64: proof photo as base64
    """
    try:
        report = get_report_by_id(task_id)
        if not report:
            return jsonify({"success": False, "error": "Task not found"}), 404

        if report.get("assigned_worker_id") != g.firebase_uid:
            return jsonify({"success": False, "error": "Task not assigned to you"}), 403

        # Handle completion data
        if request.is_json:
            data = request.get_json()
        else:
            data = request.form.to_dict()

        completion_image_url = None

        # Handle proof image upload
        if "image" in request.files:
            file = request.files["image"]
            if file.filename:
                image_data = file.read()
                file_ext = file.filename.rsplit(".", 1)[-1] if "." in file.filename else "jpg"
                file_path = f"completions/{uuid.uuid4()}.{file_ext}"
                try:
                    completion_image_url = upload_image("completion-images", file_path, image_data)
                except Exception as e:
                    logger.warning(f"Completion image upload failed: {e}")
        elif data.get("image_base64"):
            try:
                image_data = base64.b64decode(data["image_base64"])
                file_path = f"completions/{uuid.uuid4()}.jpg"
                completion_image_url = upload_image("completion-images", file_path, image_data)
            except Exception as e:
                logger.warning(f"Completion image upload failed: {e}")

        if not completion_image_url:
            completion_image_url = data.get("completion_image_url")

        updated = complete_report(task_id, {
            "completion_image_url": completion_image_url,
            "remarks": data.get("remarks", ""),
        })

        # Update worker stats
        worker = get_worker(g.firebase_uid)
        if worker:
            update_worker(g.firebase_uid, {
                "total_tasks_completed": (worker.get("total_tasks_completed", 0) or 0) + 1,
                "current_task_count": max(0, (worker.get("current_task_count", 0) or 0) - 1),
            })

        # Notify citizen
        citizen = get_user(report["user_id"])
        if citizen and citizen.get("fcm_token"):
            try:
                notify_issue_resolved(citizen["fcm_token"], task_id)
            except Exception:
                pass

        create_notification({
            "user_id": report["user_id"],
            "title": "Issue Resolved ✅",
            "body": "Your reported issue has been resolved!",
            "type": "completion",
            "report_id": task_id,
        })

        return jsonify({
            "success": True,
            "message": "Task completed successfully",
            "task": updated,
        }), 200

    except Exception as e:
        logger.error(f"Error completing task: {e}")
        return jsonify({"success": False, "error": "Failed to complete task"}), 500


# ============================================================
# ATTENDANCE
# ============================================================

@worker_bp.route("/attendance", methods=["POST"])
@token_required
@worker_required
def log_attendance():
    """
    Record worker attendance (login or logout).

    Request Body:
        {
            "type": "login" | "logout",
            "photo": "base64-encoded-photo",
            "latitude": 17.66,
            "longitude": 75.91
        }
    """
    try:
        data = request.get_json()

        attendance_type = data.get("type", "login")
        photo = data.get("photo")
        latitude = data.get("latitude")
        longitude = data.get("longitude")

        # Upload photo if provided
        photo_url = None
        if photo:
            try:
                photo_data = base64.b64decode(photo)
                file_path = f"attendance/{g.firebase_uid}/{uuid.uuid4()}.jpg"
                photo_url = upload_image("attendance-photos", file_path, photo_data)
            except Exception as e:
                logger.warning(f"Attendance photo upload failed: {e}")

        if attendance_type == "login":
            result = record_login({
                "worker_id": g.firebase_uid,
                "login_photo": photo_url,
                "latitude": latitude,
                "longitude": longitude,
            })
            # Update worker status
            update_worker(g.firebase_uid, {"status": "available"})
            message = "Login recorded successfully"
        else:
            result = record_logout({
                "worker_id": g.firebase_uid,
                "logout_photo": photo_url,
            })
            # Update worker status
            update_worker(g.firebase_uid, {"status": "offline"})
            message = "Logout recorded successfully"

        return jsonify({
            "success": True,
            "message": message,
            "attendance": result,
        }), 200

    except Exception as e:
        logger.error(f"Attendance error: {e}")
        return jsonify({"success": False, "error": "Failed to record attendance"}), 500


@worker_bp.route("/attendance/history", methods=["GET"])
@token_required
@worker_required
def attendance_history():
    """Get attendance history for current worker."""
    try:
        records = get_attendance(worker_id=g.firebase_uid, limit=30)
        return jsonify({
            "success": True,
            "attendance": records,
        }), 200
    except Exception as e:
        logger.error(f"Error fetching attendance: {e}")
        return jsonify({"success": False, "error": "Failed to fetch attendance"}), 500


# ============================================================
# ADMIN WORKER MANAGEMENT
# ============================================================

@worker_bp.route("/admin/workers", methods=["GET"])
@token_required
@admin_required
def list_workers():
    """Get all workers (admin only)."""
    try:
        status_filter = request.args.get("status")
        workers = get_workers(status=status_filter)
        return jsonify({
            "success": True,
            "workers": workers,
            "count": len(workers),
        }), 200
    except Exception as e:
        logger.error(f"Error fetching workers: {e}")
        return jsonify({"success": False, "error": "Failed to fetch workers"}), 500


@worker_bp.route("/admin/workers", methods=["POST"])
@token_required
@admin_required
def create_new_worker():
    """Create a new worker account (admin only)."""
    try:
        data = request.get_json()

        if not data.get("name"):
            return jsonify({"success": False, "error": "Worker name is required"}), 400

        worker_id = data.get("worker_id", str(uuid.uuid4()))

        # Create user record
        from services.supabase_service import create_user
        create_user({
            "uid": worker_id,
            "name": data["name"],
            "email": data.get("email", f"{worker_id}@worker.smartroad.com"),
            "role": "worker",
            "phone": data.get("phone"),
        })

        # Create worker record
        worker = create_worker({
            "worker_id": worker_id,
            "name": data["name"],
            "phone": data.get("phone"),
        })

        return jsonify({
            "success": True,
            "message": "Worker created successfully",
            "worker": worker,
        }), 201

    except Exception as e:
        logger.error(f"Error creating worker: {e}")
        return jsonify({"success": False, "error": "Failed to create worker"}), 500


@worker_bp.route("/admin/workers/<worker_id>/attendance", methods=["GET"])
@token_required
@admin_required
def worker_attendance(worker_id):
    """Get attendance records for a specific worker (admin only)."""
    try:
        records = get_attendance(worker_id=worker_id, limit=60)
        return jsonify({
            "success": True,
            "attendance": records,
        }), 200
    except Exception as e:
        logger.error(f"Error fetching worker attendance: {e}")
        return jsonify({"success": False, "error": "Failed to fetch attendance"}), 500
