# NEW FILE — Admin Routes
# Additional admin-only endpoints

from flask import Blueprint, request, jsonify, g
from services.supabase_service import (
    get_reports, get_report_stats, get_workers,
    get_attendance, get_user,
)
from middleware.auth_middleware import token_required, admin_required
from utils.logger import get_logger

logger = get_logger(__name__)

admin_bp = Blueprint("admin", __name__, url_prefix="/admin")


@admin_bp.route("/reports", methods=["GET"])
@token_required
@admin_required
def admin_all_reports():
    """Get all reports for admin management with filters."""
    try:
        filters = {}

        if request.args.get("status"):
            filters["status"] = request.args.get("status")
        if request.args.get("category"):
            filters["category"] = request.args.get("category")
        if request.args.get("worker_id"):
            filters["assigned_worker_id"] = request.args.get("worker_id")

        limit = int(request.args.get("limit", 100))
        offset = int(request.args.get("offset", 0))

        reports = get_reports(filters=filters, limit=limit, offset=offset)

        return jsonify({
            "success": True,
            "reports": reports,
            "count": len(reports),
        }), 200

    except Exception as e:
        logger.error(f"Admin reports error: {e}")
        return jsonify({"success": False, "error": "Failed to fetch reports"}), 500


@admin_bp.route("/overview", methods=["GET"])
@token_required
@admin_required
def admin_overview():
    """Complete admin overview with all dashboard data."""
    try:
        stats = get_report_stats()
        workers = get_workers()

        active_workers = sum(1 for w in workers if w.get("status") != "offline")

        return jsonify({
            "success": True,
            "overview": {
                "reports": stats,
                "workers": {
                    "total": len(workers),
                    "active": active_workers,
                    "offline": len(workers) - active_workers,
                },
            },
        }), 200

    except Exception as e:
        logger.error(f"Admin overview error: {e}")
        return jsonify({"success": False, "error": "Failed to fetch overview"}), 500


@admin_bp.route("/attendance/all", methods=["GET"])
@token_required
@admin_required
def all_attendance():
    """Get attendance records for all workers."""
    try:
        records = get_attendance(limit=100)
        return jsonify({
            "success": True,
            "attendance": records,
            "count": len(records),
        }), 200
    except Exception as e:
        logger.error(f"Attendance fetch error: {e}")
        return jsonify({"success": False, "error": "Failed to fetch attendance"}), 500
