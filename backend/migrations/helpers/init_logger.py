from logging.handlers import RotatingFileHandler
import logging


def init_logging(logger_level: int) -> bool:
    """

    Args:
        logger_level (int): _description_

    Returns:
        bool: _description_
    """
    logging.basicConfig(
        level=logging.DEBUG,
        format="[%(asctime)s] %(levelname)s [%(name)s.%(funcName)s:%(lineno)d] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    logger = logging.getLogger()
    logger.setLevel(logger_level)
    
    logger.info('Logger Initialized.')