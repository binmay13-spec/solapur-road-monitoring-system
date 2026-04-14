# NEW FILE | Extends: backend/middleware/auth_middleware.py
# Verify Firebase token using the new config and attach to flask.g

from functools import wraps
from flask import request, jsonify, g
import sys
import os

# Add parent directory to path to reach config package
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    from config.firebase_config_new import verify_id_token
except ImportError:
    # Fallback for different execution environments
    from ..config.firebase_config_new import verify_id_token

def token_required(f):
    """
    Decorator to verify Firebase ID token.
    Expects 'Authorization: Bearer <token>' header.
    """
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get("Authorization")
        
        if not auth_header:
            return jsonify({
                "success": False,
                "error": "Missing Authorization header"
            }), 401
            
        try:
            # Bearer <token>
            token = auth_header.split(" ")[1]
            decoded_token = verify_id_token(token)
            
            # Attach to flask global context
            g.uid = decoded_token.get("uid")
            g.email = decoded_token.get("email")
            g.user = decoded_token # Full claims
            
        except IndexError:
            return jsonify({
                "success": False,
                "error": "Invalid Authorization header format. Use 'Bearer <token>'"
            }), 401
        except ValueError as e:
            return jsonify({
                "success": False,
                "error": str(e)
            }), 401
        except Exception as e:
            return jsonify({
                "success": False,
                "error": "Authentication failed"
            }), 401
            
        return f(*args, **kwargs)
        
    return decorated

def admin_required(f):
    """Decorator to require admin role in token claims."""
    @wraps(f)
    def decorated(*args, **kwargs):
        if not hasattr(g, 'user') or g.user.get('role') != 'admin':
            # Note: Custom claims 'role' must be set in Firebase
            # If not using custom claims, this would check the 'users' table in Supabase
            return jsonify({
                "success": False,
                "error": "Admin privileges required"
            }), 403
        return f(*args, **kwargs)
    return decorated
