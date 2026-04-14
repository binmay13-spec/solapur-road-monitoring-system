# NEW FILE | Extends: backend/routes/admin_routes.py
# Admin specific routes for orchestration and analytics

from flask import Blueprint, request, jsonify, g
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from middleware.auth_middleware_new import token_required, admin_required
from services.report_service_new import report_service
from services.worker_service_new import worker_service
from services.auth_service_new import auth_service
from utils.logger_new import get_logger

logger = get_logger("admin_routes")
admin_bp = Blueprint("admin_new", __name__)

@admin_bp.route("/admin/reports", methods=["GET"])
@token_required
@admin_required
def admin_get_reports():
    """Fetch all reports with filters."""
    status = request.args.get("status")
    category = request.args.get("category")
    reports = report_service.get_all_reports(filters={"status": status, "category": category})
    return jsonify({"success": True, "reports": reports}), 200

@admin_bp.route("/admin/assign", methods=["POST"])
@token_required
@admin_required
def admin_assign():
    """Assign a worker to a report."""
    data = request.json
    report_id = data.get("report_id")
    worker_id = data.get("worker_id")
    
    if not all([report_id, worker_id]):
        return jsonify({"success": False, "error": "Report ID and Worker ID required"}), 400
        
    result = report_service.assign_worker(report_id, worker_id)
    return jsonify({"success": True, "report": result}), 200

@admin_bp.route("/admin/workers", methods=["GET"])
@token_required
@admin_required
def admin_get_workers():
    """List all workers."""
    workers = worker_service.get_all_workers()
    return jsonify({"success": True, "workers": workers}), 200

@admin_bp.route("/admin/worker/create", methods=["POST"])
@token_required
@admin_required
def admin_create_worker():
    """Register a new worker."""
    data = request.json
    uid = data.get("uid")
    name = data.get("name")
    phone = data.get("phone")
    email = data.get("email")
    
    if not all([uid, name, email]):
        return jsonify({"success": False, "error": "UID, Name and Email required"}), 400
        
    # Create in users table first
    auth_service.create_or_get_user(uid, email, name, role="worker")
    # Then create in workers table
    worker = worker_service.create_worker(uid, name, phone)
    
    return jsonify({"success": True, "worker": worker}), 201

@admin_bp.route("/admin/attendance", methods=["GET"])
@token_required
@admin_required
def admin_get_attendance():
    """Fetch all attendance logs."""
    worker_id = request.args.get("worker_id")
    logs = worker_service.get_attendance(worker_id)
    return jsonify({"success": True, "logs": logs}), 200

@admin_bp.route("/admin/analytics", methods=["GET"])
@token_required
@admin_required
def admin_get_analytics():
    """Fetch counts and statistics."""
    reports = report_service.get_all_reports()
    workers = worker_service.get_all_workers()
    
    active_reports = [r for r in reports if r["status"] in ["pending", "assigned", "in_progress"]]
    completed_reports = [r for r in reports if r["status"] == "completed"]
    active_workers = [w for w in workers if w["status"] == "available"]
    
    # Category distribution
    cat_counts = {}
    for r in reports:
        cat_counts[r["category"]] = cat_counts.get(r["category"], 0) + 1
        
    return jsonify({
        "success": True,
        "analytics": {
            "total_reports": len(reports),
            "active_reports": len(active_reports),
            "completed_reports": len(completed_reports),
            "total_workers": len(workers),
            "active_workers": len(active_workers),
            "category_distribution": cat_counts
        }
    }), 200

@admin_bp.route("/admin/support", methods=["GET"])
@token_required
@admin_required
def admin_get_support():
    """Fetch all support tickets."""
    from services.supabase_service import get_support_tickets
    tickets = get_support_tickets()
    return jsonify({"success": True, "tickets": tickets}), 200

@admin_bp.route("/admin/support/respond", methods=["POST"])
@token_required
@admin_required
def admin_respond_support():
    """Respond to a support ticket."""
    from services.supabase_service import respond_to_ticket
    data = request.json
    ticket_id = data.get("ticket_id")
    response = data.get("response")
    
    if not all([ticket_id, response]):
        return jsonify({"success": False, "error": "Ticket ID and response required"}), 400
        
    result = respond_to_ticket(ticket_id, response, g.uid)
    return jsonify({"success": True, "ticket": result}), 200
