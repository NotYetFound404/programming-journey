import logging

def setup_logger(name="cfd_solver", level=logging.INFO):
    """Set up a basic logger for the project."""
    logger = logging.getLogger(name)
    logger.setLevel(level)
    
    if not logger.handlers:
        ch = logging.StreamHandler()
        ch.setFormatter(logging.Formatter("%(asctime)s - %(levelname)s - %(message)s"))
        logger.addHandler(ch)
    
    return logger

logger = setup_logger()

