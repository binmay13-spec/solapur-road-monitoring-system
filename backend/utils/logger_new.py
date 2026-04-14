# NEW FILE | Extends: backend/utils/logger.py
# Structured logging with rotating file support

import logging
import os
import sys
from logging.handlers import RotatingFileHandler
from datetime import datetime

class StructuredLogger:
    def __init__(self, name="smart_road_monitor", log_dir="logs"):
        self.logger = logging.getLogger(name)
        self.logger.setLevel(logging.INFO)
        
        if not os.path.exists(log_dir):
            os.makedirs(log_dir)
            
        # Clear existing handlers if any
        if self.logger.hasHandlers():
            self.logger.handlers.clear()
            
        # Formatter: [TIMESTAMP] [LEVEL] [MODULE] MESSAGE
        formatter = logging.Formatter(
            '[%(asctime)s] [%(levelname)s] [%(name)s] %(message)s'
        )
        
        # Console Handler
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setFormatter(formatter)
        self.logger.addHandler(console_handler)
        
        # File Handler (Rotating: 10MB per file, keep 5 backups)
        file_path = os.path.join(log_dir, "app.log")
        file_handler = RotatingFileHandler(
            file_path, maxBytes=10*1024*1024, backupCount=5
        )
        file_handler.setFormatter(formatter)
        self.logger.addHandler(file_handler)

    def get_logger(self):
        return self.logger

# Global logger instance
_logger_instance = StructuredLogger().get_logger()

def get_logger(name=None):
    if name:
        return logging.getLogger(name)
    return _logger_instance

def log_info(message):
    _logger_instance.info(message)

def log_error(message, exc_info=True):
    _logger_instance.error(message, exc_info=exc_info)

def log_warning(message):
    _logger_instance.warning(message)
