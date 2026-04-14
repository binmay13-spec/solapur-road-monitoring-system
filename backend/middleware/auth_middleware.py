# NEW FILE — Authentication Middleware
# Provides @token_required decorator for protecting Flask routes

from functools import wraps
from flask import request, jsonify, g
from services.firebase_auth_service import verify_firebase_token
from services.supabase_service import get_user
from utils.logger import get_logger

logger = get_logger(__name__)


def token_required(f):
    """
    Decorator that verifies Firebase ID token from Authorization header.
    Attaches the authenticated user to flask.g.user.

    Usage:
        @app.route('/protected')
        @token_required
        def protected_route():
            user = g.user  # Authenticated user dict
    """
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get("Authorization", "")

        if not auth_header:
            return jsonify({
                "success": False,
                "error": "Authorization header missing",
            }), 401

        # Extract token from "Bearer <token>"
        parts = auth_header.split(" ")
        if len(parts) != 2 or parts[0].lower() != "bearer":
            return jsonify({
                "success": False,
                "error": "Invalid authorization format. Use: Bearer <token>",
            }), 401

        id_token = parts[1]

        try:
            # Verify Firebase token
            decoded_token = verify_firebase_token(id_token)
            uid = decoded_token.get("uid")

            if not uid:
                return jsonify({
                    "success": False,
                    "error": "Invalid token: no UID found",
                }), 401

            # Fetch user from Supabase
            user = get_user(uid)
            if not user:
                # User exists in Firebase but not in our DB — auto-create
                logger.info(f"Auto-creating user record for UID: {uid}")
                from services.supabase_service import create_user
                user = create_user({
                    "uid": uid,
                    "name": decoded_token.get("name", ""),
                    "email": decoded_token.get("email", ""),
                    "role": "citizen",  # Default role
                })

            # Attach user to request context
            g.user = user
            g.firebase_uid = uid
            g.decoded_token = decoded_token

        except ValueError as e:
            return jsonify({
                "success": False,
                "error": str(e),
            }), 401
        except Exception as e:
            logger.error(f"Authentication error: {e}")
            return jsonify({
                "success": False,
                "error": "Authentication failed",
            }), 500

        return f(*args, **kwargs)
    return decorated


def admin_required(f):
    """
    Decorator that requires the user to be an admin.
    Must be used after @token_required.

    Usage:
        @app.route('/admin/data')
        @token_required
        @admin_required
        def admin_route():
            ...
    """
    @wraps(f)
    def decorated(*args, **kwargs):
        user = getattr(g, "user", None)
        if not user or user.get("role") != "admin":
            return jsonify({
                "success": False,
                "error": "Admin access required",
            }), 403
        return f(*args, **kwargs)
    return decorated


def worker_required(f):
    """
    Decorator that requires the user to be a worker.
    Must be used after @token_required.
    """
    @wraps(f)
    def decorated(*args, **kwargs):
        user = getattr(g, "user", None)
        if not user or user.get("role") not in ("worker", "admin"):
            return jsonify({
                "success": False,
                "error": "Worker access required",
            }), 403
        return f(*args, **kwargs)
    return decorated
