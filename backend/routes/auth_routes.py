# NEW FILE — Authentication Routes
# Handles user login, registration, and profile endpoints

from flask import Blueprint, request, jsonify, g
from services.firebase_auth_service import verify_firebase_token
from services.supabase_service import create_user, get_user, update_user
from middleware.auth_middleware import token_required
from utils.logger import get_logger

logger = get_logger(__name__)

auth_bp = Blueprint("auth", __name__, url_prefix="/auth")


@auth_bp.route("/login", methods=["POST"])
def login():
    """
    Login/Register user with Firebase ID token.

    Request Body:
        {
            "id_token": "firebase-id-token",
            "role": "citizen" | "worker",
            "name": "User Name",
            "fcm_token": "optional-fcm-token"
        }

    Returns:
        User profile from Supabase
    """
    try:
        data = request.get_json()

        if not data or not data.get("id_token"):
            return jsonify({
                "success": False,
                "error": "id_token is required",
            }), 400

        # Verify Firebase token
        decoded_token = verify_firebase_token(data["id_token"])
        uid = decoded_token["uid"]
        email = decoded_token.get("email", "")
        name = data.get("name") or decoded_token.get("name", "")

        # Check if user exists in Supabase
        existing_user = get_user(uid)

        if existing_user:
            # Update FCM token if provided
            updates = {}
            if data.get("fcm_token"):
                updates["fcm_token"] = data["fcm_token"]
            if updates:
                update_user(uid, updates)
                existing_user.update(updates)

            logger.info(f"User logged in: {uid}")
            return jsonify({
                "success": True,
                "message": "Login successful",
                "user": existing_user,
            }), 200
        else:
            # Create new user
            role = data.get("role", "citizen")
            if role not in ("citizen", "worker", "admin"):
                role = "citizen"

            user = create_user({
                "uid": uid,
                "name": name,
                "email": email,
                "role": role,
                "phone": data.get("phone"),
                "avatar_url": decoded_token.get("picture"),
                "fcm_token": data.get("fcm_token"),
            })

            # If worker role, also create worker record
            if role == "worker":
                from services.supabase_service import create_worker
                create_worker({
                    "worker_id": uid,
                    "name": name,
                    "phone": data.get("phone"),
                })

            logger.info(f"New user registered: {uid} ({role})")
            return jsonify({
                "success": True,
                "message": "Registration successful",
                "user": user,
            }), 201

    except ValueError as e:
        return jsonify({"success": False, "error": str(e)}), 401
    except Exception as e:
        logger.error(f"Login error: {e}")
        return jsonify({"success": False, "error": "Login failed"}), 500


@auth_bp.route("/profile", methods=["GET"])
@token_required
def get_profile():
    """Get current user's profile."""
    return jsonify({
        "success": True,
        "user": g.user,
    }), 200


@auth_bp.route("/profile", methods=["PUT"])
@token_required
def update_profile():
    """Update current user's profile."""
    try:
        data = request.get_json()
        allowed_fields = {"name", "phone", "avatar_url", "fcm_token"}
        updates = {k: v for k, v in data.items() if k in allowed_fields}

        if not updates:
            return jsonify({
                "success": False,
                "error": "No valid fields to update",
            }), 400

        updated_user = update_user(g.firebase_uid, updates)

        return jsonify({
            "success": True,
            "message": "Profile updated",
            "user": updated_user,
        }), 200

    except Exception as e:
        logger.error(f"Profile update error: {e}")
        return jsonify({"success": False, "error": "Update failed"}), 500
