# NEW FILE — Report Routes
# Handles report creation, listing, updating, and AI detection

import os
import uuid
import base64
from flask import Blueprint, request, jsonify, g
from services.supabase_service import (
    create_report, get_reports, get_report_by_id,
    update_report, get_report_stats, upload_image,
    get_user, create_notification,
)
from services.ai_detection_service import detect_road_issue
from services.notification_service import notify_worker_assigned
from middleware.auth_middleware import token_required, admin_required
from utils.logger import get_logger

logger = get_logger(__name__)

report_bp = Blueprint("report", __name__)


@report_bp.route("/report", methods=["POST"])
@token_required
def submit_report():
    """
    Submit a new road issue report.

    Accepts multipart form data or JSON.

    Form fields:
        - category: required
        - latitude: required
        - longitude: required
        - description: optional
        - image: file upload (optional)
        - image_base64: base64 encoded image (optional)
    """
    try:
        # Handle both JSON and form data
        if request.is_json:
            data = request.get_json()
        else:
            data = request.form.to_dict()

        # Validate required fields
        category = data.get("category")
        latitude = data.get("latitude")
        longitude = data.get("longitude")

        if not category:
            return jsonify({"success": False, "error": "Category is required"}), 400
        if not latitude or not longitude:
            return jsonify({"success": False, "error": "Location is required"}), 400

        valid_categories = [
            "pothole", "road_obstruction", "water_logging",
            "broken_streetlight", "garbage",
        ]
        if category not in valid_categories:
            return jsonify({
                "success": False,
                "error": f"Invalid category. Valid: {valid_categories}",
            }), 400

        # Handle image upload
        image_url = None
        image_data = None

        # Check for file upload
        if "image" in request.files:
            file = request.files["image"]
            if file.filename:
                image_data = file.read()
                file_ext = file.filename.rsplit(".", 1)[-1] if "." in file.filename else "jpg"
                file_path = f"reports/{uuid.uuid4()}.{file_ext}"
                try:
                    image_url = upload_image("report-images", file_path, image_data)
                except Exception as e:
                    logger.warning(f"Image upload failed, continuing without image: {e}")

        # Check for base64 image
        elif data.get("image_base64"):
            try:
                image_data = base64.b64decode(data["image_base64"])
                file_path = f"reports/{uuid.uuid4()}.jpg"
                image_url = upload_image("report-images", file_path, image_data)
            except Exception as e:
                logger.warning(f"Base64 image upload failed: {e}")

        # Use provided image_url if no upload
        if not image_url:
            image_url = data.get("image_url")

        # Run AI detection on image
        ai_result = None
        if image_data:
            try:
                ai_result = detect_road_issue(image_data=image_data)
                logger.info(f"AI detection result: {ai_result.get('category')} "
                            f"(confidence: {ai_result.get('confidence')})")
            except Exception as e:
                logger.warning(f"AI detection failed, continuing: {e}")

        # Create report in Supabase
        report = create_report({
            "user_id": g.firebase_uid,
            "category": category,
            "description": data.get("description", ""),
            "image_url": image_url,
            "latitude": float(latitude),
            "longitude": float(longitude),
            "address": data.get("address"),
            "ai_detection_result": ai_result,
        })

        return jsonify({
            "success": True,
            "message": "Report submitted successfully",
            "report": report,
            "ai_detection": ai_result,
        }), 201

    except Exception as e:
        logger.error(f"Report submission error: {e}")
        return jsonify({"success": False, "error": "Failed to submit report"}), 500


@report_bp.route("/reports", methods=["GET"])
@token_required
def list_reports():
    """
    Get reports with optional filters.

    Query params:
        - status: filter by status
        - category: filter by category
        - user_id: filter by user (citizen sees own, admin sees all)
        - limit: number of results (default 50)
        - offset: pagination offset (default 0)
    """
    try:
        filters = {}

        # Citizens can only see their own reports
        if g.user.get("role") == "citizen":
            filters["user_id"] = g.firebase_uid
        elif request.args.get("user_id"):
            filters["user_id"] = request.args.get("user_id")

        if request.args.get("status"):
            filters["status"] = request.args.get("status")
        if request.args.get("category"):
            filters["category"] = request.args.get("category")

        limit = int(request.args.get("limit", 50))
        offset = int(request.args.get("offset", 0))

        reports = get_reports(filters=filters, limit=limit, offset=offset)

        return jsonify({
            "success": True,
            "reports": reports,
            "count": len(reports),
        }), 200

    except Exception as e:
        logger.error(f"Error fetching reports: {e}")
        return jsonify({"success": False, "error": "Failed to fetch reports"}), 500


@report_bp.route("/reports/<report_id>", methods=["GET"])
@token_required
def get_single_report(report_id):
    """Get a single report by ID."""
    try:
        report = get_report_by_id(report_id)
        if not report:
            return jsonify({"success": False, "error": "Report not found"}), 404

        return jsonify({"success": True, "report": report}), 200

    except Exception as e:
        logger.error(f"Error fetching report {report_id}: {e}")
        return jsonify({"success": False, "error": "Failed to fetch report"}), 500


@report_bp.route("/reports/<report_id>", methods=["PUT"])
@token_required
def update_single_report(report_id):
    """Update a report (status, assignment, etc.)."""
    try:
        data = request.get_json()
        allowed_fields = {"status", "description", "category"}
        updates = {k: v for k, v in data.items() if k in allowed_fields}

        if not updates:
            return jsonify({"success": False, "error": "No valid fields to update"}), 400

        report = update_report(report_id, updates)

        return jsonify({
            "success": True,
            "message": "Report updated",
            "report": report,
        }), 200

    except Exception as e:
        logger.error(f"Error updating report: {e}")
        return jsonify({"success": False, "error": "Failed to update report"}), 500


@report_bp.route("/assign", methods=["POST"])
@token_required
@admin_required
def assign_worker():
    """
    Assign a worker to a report. Admin only.

    Request Body:
        {
            "report_id": "uuid",
            "worker_id": "firebase-uid"
        }
    """
    try:
        data = request.get_json()

        report_id = data.get("report_id")
        worker_id = data.get("worker_id")

        if not report_id or not worker_id:
            return jsonify({
                "success": False,
                "error": "report_id and worker_id are required",
            }), 400

        from services.supabase_service import assign_worker_to_report
        report = assign_worker_to_report(report_id, worker_id)

        if report:
            # Get citizen user to send notification
            original_report = get_report_by_id(report_id)
            if original_report:
                citizen = get_user(original_report["user_id"])
                worker = get_user(worker_id)
                if citizen and citizen.get("fcm_token"):
                    try:
                        notify_worker_assigned(
                            citizen["fcm_token"],
                            report_id,
                            worker.get("name", "A worker") if worker else "A worker"
                        )
                    except Exception:
                        pass  # Don't fail assignment if notification fails

                # Create in-app notification
                create_notification({
                    "user_id": original_report["user_id"],
                    "title": "Worker Assigned",
                    "body": f"A worker has been assigned to your report.",
                    "type": "assignment",
                    "report_id": report_id,
                })

        return jsonify({
            "success": True,
            "message": "Worker assigned successfully",
            "report": report,
        }), 200

    except Exception as e:
        logger.error(f"Assignment error: {e}")
        return jsonify({"success": False, "error": "Failed to assign worker"}), 500


@report_bp.route("/admin/dashboard", methods=["GET"])
@token_required
@admin_required
def admin_dashboard():
    """Get admin dashboard statistics."""
    try:
        stats = get_report_stats()

        # Get active workers count
        from services.supabase_service import get_workers
        workers = get_workers()
        active_workers = sum(1 for w in workers if w.get("status") != "offline")

        stats["active_workers"] = active_workers
        stats["total_workers"] = len(workers)

        return jsonify({
            "success": True,
            "stats": stats,
        }), 200

    except Exception as e:
        logger.error(f"Dashboard error: {e}")
        return jsonify({"success": False, "error": "Failed to fetch dashboard data"}), 500


@report_bp.route("/admin/analytics", methods=["GET"])
@token_required
@admin_required
def admin_analytics():
    """Get detailed analytics for admin dashboard."""
    try:
        stats = get_report_stats()

        # Get all reports with location for heatmap
        all_reports = get_reports(limit=500)
        heatmap_data = [
            {
                "lat": r.get("latitude"),
                "lng": r.get("longitude"),
                "category": r.get("category"),
                "status": r.get("status"),
            }
            for r in all_reports if r.get("latitude") and r.get("longitude")
        ]

        return jsonify({
            "success": True,
            "stats": stats,
            "heatmap": heatmap_data,
        }), 200

    except Exception as e:
        logger.error(f"Analytics error: {e}")
        return jsonify({"success": False, "error": "Failed to fetch analytics"}), 500
