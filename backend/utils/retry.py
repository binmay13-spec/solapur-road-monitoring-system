# NEW FILE — Retry Utility
# Exponential backoff retry decorator for resilient operations

import time
import functools
from utils.logger import get_logger

logger = get_logger(__name__)


def retry_on_failure(max_retries: int = 3, base_delay: float = 0.5, max_delay: float = 10.0):
    """
    Decorator for automatic retry with exponential backoff.

    Args:
        max_retries: Maximum number of retry attempts
        base_delay: Initial delay in seconds
        max_delay: Maximum delay in seconds

    Usage:
        @retry_on_failure(max_retries=3)
        def fragile_function():
            ...
    """
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            last_exception = None
            for attempt in range(max_retries + 1):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    last_exception = e
                    if attempt < max_retries:
                        delay = min(base_delay * (2 ** attempt), max_delay)
                        logger.warning(
                            f"Retry {attempt + 1}/{max_retries} for {func.__name__}: "
                            f"{str(e)}. Retrying in {delay:.1f}s..."
                        )
                        time.sleep(delay)
                    else:
                        logger.error(
                            f"All {max_retries} retries exhausted for {func.__name__}: {str(e)}"
                        )

            raise last_exception
        return wrapper
    return decorator
