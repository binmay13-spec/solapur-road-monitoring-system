# NEW FILE — Do not modify existing files
# Extends: services/firebase_auth_service.py
# Firebase Admin SDK initialization using credentials from env_new.py

import firebase_admin
from firebase_admin import credentials, auth
import os
import sys

# Add parent directory to path so we can import config.env_new
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config.env_new import FIREBASE_PROJECT_ID

_firebase_app = None


def get_firebase_app():
    """
    Initialize and return the Firebase Admin SDK app (singleton).

    Uses the project ID from env_new.py. The Admin SDK can initialize
    without a service account JSON if:
      - Running on Google Cloud (uses default credentials), OR
      - GOOGLE_APPLICATION_CREDENTIALS env var is set, OR
      - A service account JSON exists at ./firebase_service.json

    For local development, place your service account JSON at
    backend/firebase_service.json and it will be auto-detected.
    """
    global _firebase_app

    if _firebase_app is not None:
        return _firebase_app

    # Check if already initialized by another module
    try:
        _firebase_app = firebase_admin.get_app()
        return _firebase_app
    except ValueError:
        pass  # Not initialized yet

    # Try service account JSON file first
    service_account_path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "firebase_service.json"
    )

    try:
        if os.path.exists(service_account_path):
            cred = credentials.Certificate(service_account_path)
            _firebase_app = firebase_admin.initialize_app(cred, {
                "projectId": FIREBASE_PROJECT_ID,
            })
            print(f"[firebase_config_new] Initialized with service account JSON.")
        else:
            # Fall back to project ID only (works on GCP or with env var)
            _firebase_app = firebase_admin.initialize_app(options={
                "projectId": FIREBASE_PROJECT_ID,
            })
            print(f"[firebase_config_new] Initialized with project ID: {FIREBASE_PROJECT_ID}")

    except Exception as e:
        print(f"[firebase_config_new] ERROR initializing Firebase: {e}")
        raise

    return _firebase_app


def verify_id_token(id_token: str) -> dict:
    """
    Verify a Firebase ID token and return the decoded claims.

    Args:
        id_token: The Firebase ID token string from the client.

    Returns:
        dict: Decoded token with uid, email, name, etc.

    Raises:
        ValueError: If the token is invalid, expired, or revoked.
    """
    get_firebase_app()  # Ensure initialized

    try:
        decoded = auth.verify_id_token(id_token)
        return decoded
    except auth.ExpiredIdTokenError:
        raise ValueError("Firebase token has expired. Please re-authenticate.")
    except auth.InvalidIdTokenError:
        raise ValueError("Invalid Firebase token.")
    except auth.RevokedIdTokenError:
        raise ValueError("Firebase token has been revoked.")
    except Exception as e:
        raise ValueError(f"Firebase token verification failed: {str(e)}")


def get_user_by_uid(uid: str) -> dict:
    """Fetch Firebase user record by UID."""
    get_firebase_app()

    try:
        user = auth.get_user(uid)
        return {
            "uid": user.uid,
            "email": user.email,
            "display_name": user.display_name,
            "photo_url": user.photo_url,
            "email_verified": user.email_verified,
        }
    except auth.UserNotFoundError:
        return None
    except Exception as e:
        print(f"[firebase_config_new] Error fetching user {uid}: {e}")
        return None


# ============================================================
# Auto-initialize on import (lazy — only when first used)
# ============================================================

if __name__ == "__main__":
    # Quick test
    app = get_firebase_app()
    print(f"Firebase app name: {app.name}")
    print(f"Firebase project ID: {app.project_id}")
