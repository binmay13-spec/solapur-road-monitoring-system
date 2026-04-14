# NEW FILE | Extends: backend/utils/retry.py
# Generic retry decorator for resilient operations

import time
from functools import wraps
import sys
import os

# Add parent directory to path to reach utils package
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils.logger_new import get_logger

logger = get_logger("retry_util")

def retry(retries=3, delay=1, exceptions=(Exception,)):
    """
    Decorator that retries a function multiple times on failure.
    Args:
        retries (int): Number of attempts.
        delay (int): Delay between attempts in seconds.
        exceptions (tuple): Exceptions to catch and retry.
    """
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            last_exception = None
            for attempt in range(1, retries + 1):
                try:
                    return fn(*args, **kwargs)
                except exceptions as e:
                    last_exception = e
                    if attempt < retries:
                        logger.warning(
                            f"Attempt {attempt}/{retries} failed for '{fn.__name__}': {e}. Retrying in {delay}s..."
                        )
                        time.sleep(delay)
                    else:
                        logger.error(
                            f"All {retries} attempts failed for '{fn.__name__}': {e}"
                        )
            raise last_exception
        return wrapper
    return decorator

def retry_call(fn, *args, retries=3, delay=1, **kwargs):
    """Functional wrapper for retrying a direct call."""
    last_exception = None
    for attempt in range(1, retries + 1):
        try:
            return fn(*args, **kwargs)
        except Exception as e:
            last_exception = e
            if attempt < retries:
                time.sleep(delay)
    raise last_exception
