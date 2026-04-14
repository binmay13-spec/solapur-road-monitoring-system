# NEW FILE — Flask Application Factory
# Main entry point for the Smart Road Monitoring System backend

import os
import sys

# Add project root to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS
from config import get_config
from utils.logger import get_logger

logger = get_logger("app")


def create_app():
    """Create and configure the Flask application."""
    config = get_config()

    app = Flask(__name__, static_folder="static")
    app.config.from_object(config)

    # Enable CORS for Flutter app
    CORS(app, resources={
        r"/*": {
            "origins": "*",
            "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
            "allow_headers": ["Content-Type", "Authorization"],
        }
    })

    # Set max upload size
    app.config["MAX_CONTENT_LENGTH"] = config.MAX_CONTENT_LENGTH

    # Ensure upload directory exists
    os.makedirs(config.UPLOAD_FOLDER, exist_ok=True)

    # --------------------------------------------------------
    # Register Blueprints
    # --------------------------------------------------------
    from routes.auth_routes import auth_bp
    from routes.report_routes import report_bp
    from routes.worker_routes import worker_bp
    from routes.admin_routes import admin_bp
    from routes.support_routes import support_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(report_bp)
    app.register_blueprint(worker_bp)
    app.register_blueprint(admin_bp)
    app.register_blueprint(support_bp)

    # --------------------------------------------------------
    # Notification endpoints
    # --------------------------------------------------------
    from middleware.auth_middleware import token_required
    from flask import request, g
    from services.supabase_service import get_notifications, mark_notification_read

    @app.route("/notifications", methods=["GET"])
    @token_required
    def get_user_notifications():
        unread_only = request.args.get("unread_only", "false").lower() == "true"
        notifications = get_notifications(g.firebase_uid, unread_only=unread_only)
        return jsonify({"success": True, "notifications": notifications}), 200

    @app.route("/notifications/<notif_id>/read", methods=["PUT"])
    @token_required
    def read_notification(notif_id):
        mark_notification_read(notif_id)
        return jsonify({"success": True, "message": "Marked as read"}), 200

    # --------------------------------------------------------
    # Health Check
    # --------------------------------------------------------
    @app.route("/health", methods=["GET"])
    def health_check():
        return jsonify({
            "status": "healthy",
            "service": "Smart Road Monitoring API",
            "version": "1.0.0",
        }), 200

    # --------------------------------------------------------
    # Admin Dashboard (Static Files)
    # --------------------------------------------------------
    @app.route("/admin/", methods=["GET"])
    @app.route("/admin", methods=["GET"])
    def admin_dashboard_page():
        return send_from_directory("static/admin", "index.html")

    @app.route("/admin/<path:filename>", methods=["GET"])
    def admin_static(filename):
        return send_from_directory("static/admin", filename)

    # --------------------------------------------------------
    # Error Handlers
    # --------------------------------------------------------
    @app.errorhandler(400)
    def bad_request(e):
        return jsonify({"success": False, "error": "Bad request"}), 400

    @app.errorhandler(404)
    def not_found(e):
        return jsonify({"success": False, "error": "Resource not found"}), 404

    @app.errorhandler(405)
    def method_not_allowed(e):
        return jsonify({"success": False, "error": "Method not allowed"}), 405

    @app.errorhandler(413)
    def payload_too_large(e):
        return jsonify({"success": False, "error": "File too large (max 16MB)"}), 413

    @app.errorhandler(500)
    def internal_error(e):
        logger.error(f"Internal server error: {e}")
        return jsonify({"success": False, "error": "Internal server error"}), 500

    logger.info("Smart Road Monitoring API initialized successfully.")
    return app


# --------------------------------------------------------
# Main Entry Point
# --------------------------------------------------------
if __name__ == "__main__":
    app = create_app()
    config = get_config()
    app.run(
        host="0.0.0.0",
        port=config.PORT,
        debug=config.DEBUG,
    )
