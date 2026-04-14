# NEW FILE — Firebase Authentication Service
# Handles Firebase Admin SDK initialization and token verification

import firebase_admin
from firebase_admin import credentials, auth
from config import get_config
from utils.logger import get_logger
import os

logger = get_logger(__name__)

_firebase_initialized = False


def initialize_firebase():
    """Initialize Firebase Admin SDK (idempotent)."""
    global _firebase_initialized
    if _firebase_initialized:
        return

    config = get_config()
    service_account_path = config.FIREBASE_SERVICE_ACCOUNT_PATH
    service_account_json = config.FIREBASE_SERVICE_ACCOUNT_JSON

    try:
        if service_account_json:
            import json
            cred_dict = json.loads(service_account_json)
            cred = credentials.Certificate(cred_dict)
            firebase_admin.initialize_app(cred)
            logger.info("Firebase Admin SDK initialized with raw JSON string.")
        elif os.path.exists(service_account_path):
            cred = credentials.Certificate(service_account_path)
            firebase_admin.initialize_app(cred)
            logger.info(f"Firebase Admin SDK initialized with service account file: {service_account_path}")
        else:
            # Try default credentials (for Cloud environments)
            firebase_admin.initialize_app()
            logger.info("Firebase Admin SDK initialized with default credentials.")

        _firebase_initialized = True
    except ValueError:
        # Already initialized
        _firebase_initialized = True
        logger.info("Firebase Admin SDK already initialized.")
    except Exception as e:
        logger.error(f"Failed to initialize Firebase: {e}")
        raise


def verify_firebase_token(id_token):
    """
    Verify a Firebase ID token and return decoded claims.

    Args:
        id_token: Firebase ID token string from client

    Returns:
        dict: Decoded token containing uid, email, etc.

    Raises:
        ValueError: If token is invalid or expired
    """
    initialize_firebase()

    try:
        decoded_token = auth.verify_id_token(id_token)
        logger.info(f"Token verified for user: {decoded_token.get('uid')}")
        return decoded_token
    except auth.ExpiredIdTokenError:
        logger.warning("Firebase token expired.")
        raise ValueError("Token has expired. Please re-authenticate.")
    except auth.InvalidIdTokenError:
        logger.warning("Invalid Firebase token.")
        raise ValueError("Invalid authentication token.")
    except auth.RevokedIdTokenError:
        logger.warning("Firebase token has been revoked.")
        raise ValueError("Token has been revoked. Please re-authenticate.")
    except Exception as e:
        logger.error(f"Token verification failed: {e}")
        raise ValueError(f"Authentication failed: {str(e)}")


def get_firebase_user(uid):
    """Fetch a Firebase user record by UID."""
    initialize_firebase()

    try:
        user_record = auth.get_user(uid)
        return {
            "uid": user_record.uid,
            "email": user_record.email,
            "display_name": user_record.display_name,
            "photo_url": user_record.photo_url,
            "email_verified": user_record.email_verified,
        }
    except auth.UserNotFoundError:
        logger.warning(f"Firebase user not found: {uid}")
        return None
    except Exception as e:
        logger.error(f"Error fetching Firebase user: {e}")
        return None
