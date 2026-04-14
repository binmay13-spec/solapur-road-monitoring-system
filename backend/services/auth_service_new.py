# NEW FILE | Extends: backend/services/supabase_service.py
# User management operations using the new Supabase config

import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config.supabase_config_new import get_supabase_service_client
from utils.retry_new import retry
from utils.logger_new import get_logger

logger = get_logger("auth_service")

class AuthService:
    def __init__(self):
        self.supabase = get_supabase_service_client()

    @retry(retries=3, delay=1)
    def create_or_get_user(self, uid, email, name=None, role="citizen"):
        """
        Upsert user record in Supabase 'users' table.
        """
        user_data = {
            "id": uid,
            "email": email,
            "role": role,
            "name": name or email.split("@")[0]
        }
        
        try:
            # upsert based on 'id' (primary key)
            result = self.supabase.table("users").upsert(user_data).execute()
            if result.data:
                logger.info(f"User synced: {uid} ({role})")
                return result.data[0]
            return None
        except Exception as e:
            logger.error(f"Error upserting user {uid}: {e}")
            raise

    @retry(retries=3, delay=1)
    def get_user_by_uid(self, uid):
        """Fetch user profile from Supabase."""
        try:
            result = self.supabase.table("users").select("*").eq("id", uid).execute()
            if result.data:
                return result.data[0]
            return None
        except Exception as e:
            logger.error(f"Error fetching user {uid}: {e}")
            raise

    @retry(retries=3, delay=1)
    def update_user_role(self, uid, role):
        """Update user role (Admin only operation)."""
        try:
            result = self.supabase.table("users").update({"role": role}).eq("id", uid).execute()
            return result.data[0] if result.data else None
        except Exception as e:
            logger.error(f"Error updating role for {uid}: {e}")
            raise

# Singleton instance
auth_service = AuthService()
