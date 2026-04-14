# NEW FILE | Extends: backend/services/supabase_service.py
# Report lifecycle management service

import sys
import os
from datetime import datetime

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config.supabase_config_new import get_supabase_service_client
from utils.retry_new import retry
from utils.logger_new import get_logger

logger = get_logger("report_service")

class ReportService:
    def __init__(self):
        self.supabase = get_supabase_service_client()

    @retry(retries=3, delay=1)
    def create_report(self, user_id, category, description, image_url, lat, lng):
        """Submit a new road issue report."""
        report_data = {
            "user_id": user_id,
            "category": category,
            "description": description,
            "image_url": image_url,
            "latitude": lat,
            "longitude": lng,
            "status": "pending"
        }
        
        try:
            result = self.supabase.table("reports").insert(report_data).execute()
            if result.data:
                logger.info(f"Report created by {user_id}: {result.data[0]['id']}")
                return result.data[0]
            return None
        except Exception as e:
            logger.error(f"Error creating report: {e}")
            raise

    def get_reports_by_user(self, user_id):
        """Fetch all reports submitted by a specific citizen."""
        try:
            result = self.supabase.table("reports").select("*").eq("user_id", user_id).order("created_at", desc=True).execute()
            return result.data or []
        except Exception as e:
            logger.error(f"Error fetching reports for {user_id}: {e}")
            return []

    def get_all_reports(self, filters=None):
        """Fetch all reports with optional filtering (Admin/Map)."""
        try:
            query = self.supabase.table("reports").select("*, users(name, email)")
            
            if filters:
                if filters.get("status"):
                    query = query.eq("status", filters["status"])
                if filters.get("category"):
                    query = query.eq("category", filters["category"])
            
            result = query.order("created_at", desc=True).execute()
            return result.data or []
        except Exception as e:
            logger.error(f"Error fetching all reports: {e}")
            return []

    @retry(retries=3, delay=1)
    def assign_worker(self, report_id, worker_id):
        """Assign a worker to an existing report."""
        try:
            update_data = {
                "assigned_worker_id": worker_id,
                "status": "assigned",
                "updated_at": datetime.utcnow().isoformat()
            }
            result = self.supabase.table("reports").update(update_data).eq("id", report_id).execute()
            
            # Also update worker status to busy
            self.supabase.table("workers").update({"status": "busy"}).eq("worker_id", worker_id).execute()
            
            logger.info(f"Report {report_id} assigned to worker {worker_id}")
            return result.data[0] if result.data else None
        except Exception as e:
            logger.error(f"Error assigning worker: {e}")
            raise

    @retry(retries=3, delay=1)
    def complete_report(self, report_id, proof_url, remarks):
        """Mark report as completed with proof and remarks."""
        try:
            update_data = {
                "status": "completed",
                "image_url": proof_url, # Or a separate completion_image_url if table allows
                "description": f"{remarks} (Original: ...)" if remarks else None, # Simplified for proxy
                "updated_at": datetime.utcnow().isoformat()
            }
            # Note: The table schema provided says 'reports' has status, assigned_worker_id, etc.
            result = self.supabase.table("reports").update(update_data).eq("id", report_id).execute()
            
            # Update worker status back to available
            report = result.data[0] if result.data else None
            if report and report.get("assigned_worker_id"):
                self.supabase.table("workers").update({"status": "available"}).eq("worker_id", report["assigned_worker_id"]).execute()
            
            logger.info(f"Report {report_id} completed.")
            return report
        except Exception as e:
            logger.error(f"Error completing report {report_id}: {e}")
            raise

# Singleton instance
report_service = ReportService()
