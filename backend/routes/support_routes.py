# NEW FILE — Support Ticket Routes
# Handles citizen support requests and admin responses

from flask import Blueprint, request, jsonify, g
from services.supabase_service import (
    create_support_ticket, get_support_tickets, respond_to_ticket,
)
from middleware.auth_middleware import token_required, admin_required
from utils.logger import get_logger

logger = get_logger(__name__)

support_bp = Blueprint("support", __name__, url_prefix="/support")


@support_bp.route("", methods=["POST"])
@token_required
def submit_ticket():
    """
    Submit a support ticket.

    Request Body:
        {
            "message": "My issue description..."
        }
    """
    try:
        data = request.get_json()

        if not data or not data.get("message"):
            return jsonify({"success": False, "error": "Message is required"}), 400

        ticket = create_support_ticket({
            "user_id": g.firebase_uid,
            "message": data["message"],
        })

        return jsonify({
            "success": True,
            "message": "Support ticket submitted",
            "ticket": ticket,
        }), 201

    except Exception as e:
        logger.error(f"Support ticket error: {e}")
        return jsonify({"success": False, "error": "Failed to create ticket"}), 500


@support_bp.route("/tickets", methods=["GET"])
@token_required
def list_tickets():
    """Get support tickets. Citizens see own, admins see all."""
    try:
        user_id = None
        status = request.args.get("status")

        if g.user.get("role") != "admin":
            user_id = g.firebase_uid

        tickets = get_support_tickets(user_id=user_id, status=status)

        return jsonify({
            "success": True,
            "tickets": tickets,
            "count": len(tickets),
        }), 200

    except Exception as e:
        logger.error(f"Error fetching tickets: {e}")
        return jsonify({"success": False, "error": "Failed to fetch tickets"}), 500


@support_bp.route("/tickets/<ticket_id>/respond", methods=["PUT"])
@token_required
@admin_required
def respond_ticket(ticket_id):
    """
    Respond to a support ticket (admin only).

    Request Body:
        {
            "response": "Admin response text..."
        }
    """
    try:
        data = request.get_json()

        if not data or not data.get("response"):
            return jsonify({"success": False, "error": "Response is required"}), 400

        ticket = respond_to_ticket(ticket_id, data["response"], g.firebase_uid)

        return jsonify({
            "success": True,
            "message": "Response sent",
            "ticket": ticket,
        }), 200

    except Exception as e:
        logger.error(f"Ticket response error: {e}")
        return jsonify({"success": False, "error": "Failed to respond to ticket"}), 500
