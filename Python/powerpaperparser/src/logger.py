"""Logger for CRS"""

import datetime
import logging
import os
import shutil
import sys
import traceback
import types
from pathlib import Path


def init_logging() -> logging.Logger:
    """Logger init helper."""
    formatter = logging.Formatter("[%(asctime)s.%(msecs)d][%(levelname)s][%(name)s] %(message)s")
    formatter.datefmt = "%Y-%m-%d %H:%M:%S"

    logger = logging.getLogger("CRS")
    logger.handlers.clear()  # clear all handler
    logger.setLevel(logging.DEBUG)

    sratch_env = os.environ.get("AIXCC_CRS_SCRATCH_SPACE")
    scratch_space = Path(sratch_env or "")
    log_file_name = f"crs_{datetime.datetime.now()}.log" if sratch_env else "crs.log"

    handler = logging.FileHandler(scratch_space / log_file_name)
    handler.setFormatter(formatter)
    handler.setLevel(logging.DEBUG)
    logger.addHandler(handler)

    # https://stackoverflow.com/a/60523940
    def exc_handler(exctype: type[BaseException], value: BaseException, tb: types.TracebackType | None):
        logger.exception("".join(traceback.format_exception(exctype, value, tb)))
        # mark log file as exception log
        handler.close()
        logger.removeHandler(handler)
        shutil.move(scratch_space / log_file_name, scratch_space / (log_file_name + f".{exctype.__name__}"))
        sys.__excepthook__(exctype, value, tb)

    sys.excepthook = exc_handler

    logger.info("Logger initialized")

    return logger


crs_logger = init_logging()
