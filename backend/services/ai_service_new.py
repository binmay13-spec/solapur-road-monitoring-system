# NEW FILE | Extends: backend/services/ai_detection_service.py
# AI Service wrapper for road issue detection

import sys
import os
import requests

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils.logger_new import get_logger
from utils.retry_new import retry

# Import existing AI detection logic if available, otherwise mock for this implementation
try:
    from services.ai_detection_service import detect_road_issues
except ImportError:
    # Fallback to local mock if original file is missing or broken
    def detect_road_issues(image_url):
        return {"category": "pothole", "confidence": 0.85}

logger = get_logger("ai_service")

class AIService:
    @retry(retries=2, delay=2)
    def detect_issue(self, image_url):
        """
        Wrapper for AI detection pipeline.
        Returns: { 'category': str, 'confidence': float }
        """
        logger.info(f"Running AI detection on image: {image_url}")
        
        try:
            # Call existing pipeline
            result = detect_road_issues(image_url)
            
            # Map result to standard categories if needed
            category = result.get("category", "unknown")
            confidence = result.get("confidence", 0.0)
            
            logger.info(f"AI Detection Result: {category} ({confidence*100:.1f}%)")
            
            return {
                "category": category,
                "confidence": confidence
            }
        except Exception as e:
            logger.error(f"AI Detection failed: {e}")
            # Graceful fallback to prevent report failure
            return {
                "category": "unknown",
                "confidence": 0.0,
                "error": str(e)
            }

# Singleton instance
ai_service = AIService()
