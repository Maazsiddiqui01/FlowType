from __future__ import annotations

import logging
from logging.handlers import RotatingFileHandler

from flowtype.config import GeneralConfig


def configure_logging(settings: GeneralConfig) -> logging.Logger:
    logger = logging.getLogger("flowtype")
    log_level = getattr(logging, settings.log_level.upper(), logging.INFO)
    if logger.handlers:
        logger.setLevel(log_level)
        for handler in logger.handlers:
            handler.setLevel(log_level)
        return logger

    logger.setLevel(log_level)
    logger.propagate = False

    settings.log_file.parent.mkdir(parents=True, exist_ok=True)

    formatter = logging.Formatter(
        "%(asctime)s | %(levelname)s | %(threadName)s | %(name)s | %(message)s"
    )

    file_handler = RotatingFileHandler(
        settings.log_file,
        maxBytes=1_000_000,
        backupCount=3,
        encoding="utf-8",
    )
    file_handler.setFormatter(formatter)
    file_handler.setLevel(log_level)

    console_handler = logging.StreamHandler()
    console_handler.setFormatter(formatter)
    console_handler.setLevel(log_level)

    logger.addHandler(file_handler)
    logger.addHandler(console_handler)
    return logger
