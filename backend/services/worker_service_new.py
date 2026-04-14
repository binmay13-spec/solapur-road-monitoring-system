# NEW FILE | Extends: backend/services/supabase_service.py
# Worker and Attendance management service

import sys
import os
from datetime import datetime

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config.supabase_config_new import get_supabase_service_client
from utils.retry_new import retry
from utils.logger_new import get_logger

logger = get_logger("worker_service")

class WorkerService:
    def __init__(self):
        self.supabase = get_supabase_service_client()

    def get_tasks(self, worker_id):
        """Fetch all tasks assigned to a specific worker."""
        try:
            result = self.supabase.table("reports").select("*").eq("assigned_worker_id", worker_id).order("updated_at", desc=True).execute()
            return result.data or []
        except Exception as e:
            logger.error(f"Error fetching tasks for worker {worker_id}: {e}")
            return []

    @retry(retries=3, delay=1)
    def log_attendance(self, worker_id, type="login", photo_url=None, lat=None, lng=None):
        """Record worker login/logout with proof and GPS."""
        try:
            data = {
                "worker_id": worker_id,
                "latitude": lat,
                "longitude": lng
            }
            
            if type == "login":
                data["login_time"] = datetime.utcnow().isoformat()
                data["login_photo"] = photo_url
                # Try to upsert into today's record or new record? 
                # Schema 'attendance' has (id, worker_id, login_time, logout_time, ...)
                result = self.supabase.table("attendance").insert(data).execute()
                self.supabase.table("workers").update({"status": "available"}).eq("worker_id", worker_id).execute()
            else:
                # Update existing record for today (simplistic match)
                data["logout_time"] = datetime.utcnow().isoformat()
                data["logout_photo"] = photo_url
                # Find most recent login for this worker without logout
                recent = self.supabase.table("attendance").select("id").eq("worker_id", worker_id).is_("logout_time", "null").order("login_time", desc=True).limit(1).execute()
                
                if recent.data:
                    result = self.supabase.table("attendance").update(data).eq("id", recent.data[0]["id"]).execute()
                else:
                    result = self.supabase.table("attendance").insert(data).execute()
                
                self.supabase.table("workers").update({"status": "offline"}).eq("worker_id", worker_id).execute()

            logger.info(f"Attendance {type} recorded for worker {worker_id}")
            return result.data[0] if result.data else None
        except Exception as e:
            logger.error(f"Error logging attendance for {worker_id}: {e}")
            raise

    def get_attendance(self, worker_id=None):
        """Fetch attendance logs (single worker or all for Admin)."""
        try:
            query = self.supabase.table("attendance").select("*, workers(name)")
            if worker_id:
                query = query.eq("worker_id", worker_id)
            
            result = query.order("login_time", desc=True).execute()
            return result.data or []
        except Exception as e:
            logger.error(f"Error fetching attendance logs: {e}")
            return []

    def get_all_workers(self):
        """List all registered workers."""
        try:
            result = self.supabase.table("workers").select("*").execute()
            return result.data or []
        except Exception as e:
            logger.error(f"Error listing workers: {e}")
            return []

    @retry(retries=3, delay=1)
    def create_worker(self, worker_id, name, phone):
        """Register a new worker."""
        try:
            data = {
                "worker_id": worker_id,
                "name": name,
                "phone": phone,
                "status": "offline"
            }
            result = self.supabase.table("workers").upsert(data).execute()
            return result.data[0] if result.data else None
        except Exception as e:
            logger.error(f"Error creating worker: {e}")
            raise

# Singleton instance
worker_service = WorkerService()
