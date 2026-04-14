# NEW FILE — Backend configuration
# Loads all environment variables with sensible defaults

import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    """Base configuration."""

    # Flask
    SECRET_KEY = os.getenv("SECRET_KEY")
    if os.getenv("FLASK_ENV") == "production" and not SECRET_KEY:
        raise RuntimeError("SECRET_KEY must be set in production environment!")
    
    SECRET_KEY = SECRET_KEY or "dev-secret-key-fallback"
    FLASK_ENV = os.getenv("FLASK_ENV", "development")
    DEBUG = os.getenv("FLASK_DEBUG", "true").lower() == "true"
    PORT = int(os.getenv("FLASK_PORT", 5000))

    # Supabase
    SUPABASE_URL = os.getenv("SUPABASE_URL", "")
    SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY", "")
    SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")

    # Firebase
    # Support both file path and raw JSON string (for Render secrets/env vars)
    FIREBASE_SERVICE_ACCOUNT_PATH = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH", "./firebase_service.json")
    FIREBASE_SERVICE_ACCOUNT_JSON = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
    FIREBASE_PROJECT_ID = os.getenv("FIREBASE_PROJECT_ID", "")

    # Roboflow AI
    ROBOFLOW_API_KEY = os.getenv("ROBOFLOW_API_KEY", "")
    ROBOFLOW_WORKSPACE = os.getenv("ROBOFLOW_WORKSPACE", "")
    ROBOFLOW_PROJECT = os.getenv("ROBOFLOW_PROJECT", "")
    ROBOFLOW_MODEL_VERSION = int(os.getenv("ROBOFLOW_MODEL_VERSION", 1))

    # FCM
    FCM_SERVER_KEY = os.getenv("FCM_SERVER_KEY", "")

    # File uploads
    UPLOAD_FOLDER = os.getenv("UPLOAD_FOLDER", "./uploads")
    MAX_CONTENT_LENGTH = int(os.getenv("MAX_CONTENT_LENGTH", 16 * 1024 * 1024))


class DevelopmentConfig(Config):
    pass


class ProductionConfig(Config):
    DEBUG = False
    FLASK_ENV = "production"


config_map = {
    "development": DevelopmentConfig,
    "production": ProductionConfig,
}


def get_config():
    env = os.getenv("FLASK_ENV", "development")
    return config_map.get(env, DevelopmentConfig)()
