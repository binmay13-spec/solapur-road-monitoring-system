# NEW FILE — Do not modify existing files
# Extends: services/supabase_service.py
# Supabase client initialization using credentials from env_new.py

import os
import sys

# Add parent directory to path so we can import config.env_new
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config.env_new import SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY

try:
    from supabase import create_client, Client
except ImportError:
    raise ImportError(
        "supabase package not installed. Run: pip install supabase"
    )

_supabase_anon_client: Client = None
_supabase_service_client: Client = None


def get_supabase_client() -> Client:
    """
    Get the Supabase client using the ANON key (singleton).

    The anon key respects Row Level Security (RLS) policies.
    Use this for operations where the user's identity matters.

    Returns:
        supabase.Client: Initialized Supabase client
    """
    global _supabase_anon_client

    if _supabase_anon_client is not None:
        return _supabase_anon_client

    if not SUPABASE_URL:
        raise ValueError("SUPABASE_URL is not configured in env_new.py")
    if not SUPABASE_ANON_KEY:
        raise ValueError("SUPABASE_ANON_KEY is not configured in env_new.py")

    try:
        _supabase_anon_client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)
        print(f"[supabase_config_new] Anon client connected to: {SUPABASE_URL}")
        return _supabase_anon_client
    except Exception as e:
        print(f"[supabase_config_new] ERROR connecting to Supabase: {e}")
        raise


def get_supabase_service_client() -> Client:
    """
    Get the Supabase client using the SERVICE ROLE key (singleton).

    The service role key bypasses RLS — use only in the backend
    for admin operations (creating users, assigning tasks, etc.)

    Returns:
        supabase.Client: Initialized Supabase client with elevated privileges

    Raises:
        ValueError: If SUPABASE_SERVICE_ROLE_KEY is not set in env_new.py
    """
    global _supabase_service_client

    if _supabase_service_client is not None:
        return _supabase_service_client

    if not SUPABASE_URL:
        raise ValueError("SUPABASE_URL is not configured in env_new.py")
    if not SUPABASE_SERVICE_ROLE_KEY:
        raise ValueError(
            "SUPABASE_SERVICE_ROLE_KEY is not configured in env_new.py. "
            "Get it from Supabase Dashboard > Settings > API > service_role key."
        )

    try:
        _supabase_service_client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
        print(f"[supabase_config_new] Service client connected to: {SUPABASE_URL}")
        return _supabase_service_client
    except Exception as e:
        print(f"[supabase_config_new] ERROR connecting to Supabase (service): {e}")
        raise


def test_connection() -> bool:
    """
    Quick connectivity test — attempts a lightweight query.

    Returns:
        bool: True if connection succeeds
    """
    try:
        client = get_supabase_client()
        # Try to query the users table (will return empty if no data, but confirms connectivity)
        result = client.table("users").select("id").limit(1).execute()
        print(f"[supabase_config_new] Connection test passed. Response: {len(result.data)} rows")
        return True
    except Exception as e:
        print(f"[supabase_config_new] Connection test FAILED: {e}")
        return False


# ============================================================
# Package __init__
# ============================================================

# Create config/__init__.py if it doesn't exist
_init_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "__init__.py")
if not os.path.exists(_init_path):
    with open(_init_path, "w") as f:
        f.write("# Config package\n")


# ============================================================
# Self-test when run directly
# ============================================================

if __name__ == "__main__":
    print(f"Supabase URL: {SUPABASE_URL}")
    print(f"Anon key: {SUPABASE_ANON_KEY[:20]}...")
    print(f"Service key configured: {'Yes' if SUPABASE_SERVICE_ROLE_KEY else 'No'}")
    print()
    print("Testing anon client connection...")
    test_connection()
