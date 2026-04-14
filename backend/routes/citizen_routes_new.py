# NEW FILE | Extends: backend/routes/report_routes.py
# Citizen specific routes for reporting and viewing history

from flask import Blueprint, request, jsonify, g
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from middleware.auth_middleware_new import token_required
from services.report_service_new import report_service
from services.ai_service_new import ai_service
from services.auth_service_new import auth_service
from utils.logger_new import get_logger

logger = get_logger("citizen_routes")
citizen_bp = Blueprint("citizen_new", __name__)

@citizen_bp.route("/citizen/report", methods=["POST"])
@token_required
def report_issue():
    """
    Create a new report, run AI detection, and store in database.
    """
    data = request.json
    uid = g.uid
    email = g.email
    name = g.user.get("name")
    
    # Ensure user exists in Supabase
    auth_service.create_or_get_user(uid, email, name, role="citizen")
    
    category = data.get("category")
    description = data.get("description")
    image_url = data.get("image_url") # Should be uploaded to Supabase Storage by Flutter
    lat = data.get("latitude")
    lng = data.get("longitude")
    
    if not all([category, lat, lng]):
        return jsonify({"success": False, "error": "Missing required fields"}), 400
        
    # Run AI detection if image exists
    ai_result = None
    if image_url:
        ai_result = ai_service.detect_issue(image_url)
        # If AI detects a different category with high confidence, we could override or add flags
        logger.info(f"AI Detection Result for {uid}: {ai_result}")

    # Create report
    report = report_service.create_report(
        user_id=uid,
        category=category,
        description=description,
        image_url=image_url,
        lat=lat,
        lng=lng
    )
    
    return jsonify({
        "success": True, 
        "report": report,
        "ai_detection": ai_result
    }), 201

@citizen_bp.route("/citizen/reports", methods=["GET"])
@token_required
def get_my_reports():
    """Fetch reports submitted by the authenticated user."""
    reports = report_service.get_reports_by_user(g.uid)
    return jsonify({"success": True, "reports": reports}), 200

@citizen_bp.route("/citizen/map", methods=["GET"])
@token_required
def get_map_reports():
    """Fetch all reports for display on map."""
    # Filter only relevant statuses for public map if needed
    reports = report_service.get_all_reports()
    return jsonify({"success": True, "reports": reports}), 200

@citizen_bp.route("/citizen/support", methods=["POST"])
@token_required
def submit_ticket():
    """Submit a support ticket."""
    from services.supabase_service import create_support_ticket
    data = request.json
    message = data.get("message")
    
    if not message:
        return jsonify({"success": False, "error": "Message required"}), 400
        
    ticket = create_support_ticket({
        "user_id": g.uid,
        "message": message
    })
    
    return jsonify({"success": True, "ticket": ticket}), 201
