# NEW FILE | Extends: backend/routes/worker_routes.py
# Worker specific routes for task management and attendance

from flask import Blueprint, request, jsonify, g
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from middleware.auth_middleware_new import token_required
from services.worker_service_new import worker_service
from services.report_service_new import report_service
from utils.logger_new import get_logger

logger = get_logger("worker_routes")
worker_bp = Blueprint("worker_new", __name__)

@worker_bp.route("/worker/tasks", methods=["GET"])
@token_required
def get_worker_tasks():
    """Fetch assigned tasks for the worker."""
    tasks = worker_service.get_tasks(g.uid)
    return jsonify({"success": True, "tasks": tasks}), 200

@worker_bp.route("/worker/attendance/login", methods=["POST"])
@token_required
def attendance_login():
    """Record worker login with photo and GPS."""
    data = request.json
    photo_url = data.get("photo_url")
    lat = data.get("latitude")
    lng = data.get("longitude")
    
    if not all([photo_url, lat, lng]):
        return jsonify({"success": False, "error": "Photo and location required"}), 400
        
    record = worker_service.log_attendance(
        worker_id=g.uid,
        type="login",
        photo_url=photo_url,
        lat=lat,
        lng=lng
    )
    
    return jsonify({"success": True, "record": record}), 200

@worker_bp.route("/worker/attendance/logout", methods=["POST"])
@token_required
def attendance_logout():
    """Record worker logout with photo and GPS."""
    data = request.json
    photo_url = data.get("photo_url")
    lat = data.get("latitude")
    lng = data.get("longitude")
    
    record = worker_service.log_attendance(
        worker_id=g.uid,
        type="logout",
        photo_url=photo_url,
        lat=lat,
        lng=lng
    )
    
    return jsonify({"success": True, "record": record}), 200

@worker_bp.route("/worker/task/complete", methods=["POST"])
@token_required
def complete_task():
    """Mark a task as completed with proof and remarks."""
    data = request.json
    report_id = data.get("report_id")
    proof_url = data.get("proof_url")
    remarks = data.get("remarks")
    
    if not all([report_id, proof_url]):
        return jsonify({"success": False, "error": "Report ID and proof required"}), 400
        
    # Verify the report belongs to this worker (Simple check)
    tasks = worker_service.get_tasks(g.uid)
    if not any(t["id"] == report_id for t in tasks):
        return jsonify({"success": False, "error": "Task not found or not assigned to you"}), 404
        
    result = report_service.complete_report(report_id, proof_url, remarks)
    
    return jsonify({"success": True, "report": result}), 200
