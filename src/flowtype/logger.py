from __future__ import annotations

import faulthandler
import logging
import sys
import threading
from logging.handlers import RotatingFileHandler

from flowtype.config import GeneralConfig


# Keep the faulthandler file open for the process lifetime; closing it disables the dump.
_FAULTHANDLER_FILE = None
_CRASH_HANDLERS_INSTALLED = False


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


def install_crash_handlers(settings: GeneralConfig) -> None:
    """Ensure no crash dies silently: dump native faults to a file and log every
    unhandled exception from the main thread and any background thread.

    FlowType ships under pythonw (no console) and does most work on daemon threads,
    so without this a segfault or an unhandled worker-thread exception would vanish.
    """
    global _FAULTHANDLER_FILE, _CRASH_HANDLERS_INSTALLED
    if _CRASH_HANDLERS_INSTALLED:
        return

    logger = logging.getLogger("flowtype")

    try:
        settings.log_file.parent.mkdir(parents=True, exist_ok=True)
        _FAULTHANDLER_FILE = open(settings.log_file.parent / "faulthandler.log", "a", encoding="utf-8")
        faulthandler.enable(file=_FAULTHANDLER_FILE, all_threads=True)
    except Exception as exc:  # pragma: no cover - best effort
        logger.warning("Could not enable faulthandler: %s", exc)

    def _excepthook(exc_type, exc_value, exc_tb) -> None:
        if issubclass(exc_type, KeyboardInterrupt):
            sys.__excepthook__(exc_type, exc_value, exc_tb)
            return
        logger.critical("Unhandled exception", exc_info=(exc_type, exc_value, exc_tb))

    sys.excepthook = _excepthook

    def _thread_excepthook(args: "threading.ExceptHookArgs") -> None:
        if issubclass(args.exc_type, SystemExit):
            return
        logger.critical(
            "Unhandled exception in thread %s",
            getattr(args.thread, "name", "<unknown>"),
            exc_info=(args.exc_type, args.exc_value, args.exc_traceback),
        )

    threading.excepthook = _thread_excepthook
    _CRASH_HANDLERS_INSTALLED = True
    logger.info("Crash handlers installed (faulthandler + excepthooks)")
