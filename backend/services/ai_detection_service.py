# NEW FILE — AI Detection Service
# Integrates with Roboflow for road issue detection

from config import get_config
from utils.logger import get_logger
from utils.retry import retry_on_failure
import os
import base64
import tempfile
import requests

logger = get_logger(__name__)

_model = None


def _init_roboflow():
    """Initialize Roboflow model (lazy loading)."""
    global _model
    if _model is not None:
        return _model

    config = get_config()
    api_key = config.ROBOFLOW_API_KEY

    if not api_key:
        logger.warning("Roboflow API key not configured. AI detection disabled.")
        return None

    try:
        from roboflow import Roboflow
        rf = Roboflow(api_key=api_key)
        project = rf.workspace(config.ROBOFLOW_WORKSPACE).project(config.ROBOFLOW_PROJECT)
        _model = project.version(config.ROBOFLOW_MODEL_VERSION).model
        logger.info("Roboflow model initialized successfully.")
        return _model
    except Exception as e:
        logger.error(f"Failed to initialize Roboflow: {e}")
        return None


@retry_on_failure(max_retries=2)
def detect_road_issue(image_data: bytes = None, image_path: str = None, image_url: str = None) -> dict:
    """
    Run AI detection on an image.

    Args:
        image_data: Raw image bytes
        image_path: Path to a local image file
        image_url: URL of an image

    Returns:
        dict with detection results:
        {
            "detected": True/False,
            "category": "pothole" | "water_logging" | ...,
            "confidence": 0.95,
            "predictions": [...],
            "raw": { full model response }
        }
    """
    model = _init_roboflow()

    if model is None:
        logger.warning("AI model not available — returning empty detection.")
        return {
            "detected": False,
            "category": None,
            "confidence": 0,
            "predictions": [],
            "raw": None,
            "error": "AI model not configured",
        }

    temp_path = None
    try:
        # If we have bytes, write to temp file
        if image_data:
            temp_file = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
            temp_file.write(image_data)
            temp_file.close()
            temp_path = temp_file.name
            predict_path = temp_path
        elif image_path:
            predict_path = image_path
        elif image_url:
            predict_path = image_url
        else:
            return {"detected": False, "error": "No image provided"}

        # Run prediction
        prediction = model.predict(predict_path, confidence=40, overlap=30)
        result_json = prediction.json()

        # Parse predictions
        predictions = result_json.get("predictions", [])

        if not predictions:
            return {
                "detected": False,
                "category": None,
                "confidence": 0,
                "predictions": [],
                "raw": result_json,
            }

        # Get highest confidence prediction
        best = max(predictions, key=lambda p: p.get("confidence", 0))

        # Map class names to our categories
        category_map = {
            "pothole": "pothole",
            "potholes": "pothole",
            "water_logging": "water_logging",
            "waterlogging": "water_logging",
            "flooding": "water_logging",
            "road_obstruction": "road_obstruction",
            "obstruction": "road_obstruction",
            "broken_streetlight": "broken_streetlight",
            "streetlight": "broken_streetlight",
            "garbage": "garbage",
            "trash": "garbage",
            "litter": "garbage",
        }

        detected_class = best.get("class", "").lower()
        mapped_category = category_map.get(detected_class, detected_class)

        return {
            "detected": True,
            "category": mapped_category,
            "confidence": round(best.get("confidence", 0), 4),
            "predictions": [
                {
                    "class": p.get("class"),
                    "confidence": round(p.get("confidence", 0), 4),
                    "x": p.get("x"),
                    "y": p.get("y"),
                    "width": p.get("width"),
                    "height": p.get("height"),
                }
                for p in predictions
            ],
            "raw": result_json,
        }

    except Exception as e:
        logger.error(f"AI detection failed: {e}")
        return {
            "detected": False,
            "category": None,
            "confidence": 0,
            "predictions": [],
            "error": str(e),
        }
    finally:
        # Clean up temp file
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)


def get_supported_categories() -> list:
    """Return list of supported detection categories."""
    return [
        "pothole",
        "water_logging",
        "road_obstruction",
        "broken_streetlight",
        "garbage",
    ]
