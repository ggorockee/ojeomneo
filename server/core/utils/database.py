"""
Database utility functions for connection health checking.
"""
import logging
from django.db import connection
from django.db.utils import OperationalError
from asgiref.sync import sync_to_async

logger = logging.getLogger(__name__)


def check_database_connection() -> tuple[bool, str]:
    """
    Check if database connection is alive and accessible.

    Returns:
        tuple[bool, str]: (is_connected, message)
            - is_connected: True if connection successful, False otherwise
            - message: Status message describing the connection state
    """
    try:
        # Attempt to access database
        connection.ensure_connection()

        # Test with a simple query
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()

        db_name = connection.settings_dict.get('NAME', 'unknown')
        db_host = connection.settings_dict.get('HOST', 'localhost')
        db_port = connection.settings_dict.get('PORT', '5432')

        success_msg = f"Database connection successful: {db_name}@{db_host}:{db_port}"
        logger.info(success_msg)
        return True, success_msg

    except OperationalError as e:
        error_msg = f"Database connection failed: {str(e)}"
        logger.error(error_msg)
        return False, error_msg

    except Exception as e:
        error_msg = f"Unexpected database error: {str(e)}"
        logger.critical(error_msg)
        return False, error_msg


async def check_database_connection_async() -> tuple[bool, str]:
    """
    Async version: Check if database connection is alive and accessible.

    This function wraps the synchronous database check in an async-safe manner
    using Django's sync_to_async adapter.

    Returns:
        tuple[bool, str]: (is_connected, message)
            - is_connected: True if connection successful, False otherwise
            - message: Status message describing the connection state
    """
    return await sync_to_async(check_database_connection)()
