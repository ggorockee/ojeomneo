"""
Health check API endpoint for monitoring server status.
"""
from ninja import Router
from typing import Dict, Any
from core.utils.database import check_database_connection_async

router = Router()


@router.get("/healthcheck", tags=["Health"])
async def healthcheck(request) -> Dict[str, Any]:
    """
    Async health check endpoint to verify server and database connectivity.

    This endpoint uses async/await for non-blocking database checks,
    improving overall API performance and scalability.

    Returns:
        Dict containing status information including database connectivity
    """
    db_connected, db_message = await check_database_connection_async()

    return {
        "status": "ok" if db_connected else "degraded",
        "message": "Server is running",
        "database": {
            "connected": db_connected,
            "message": db_message
        }
    }
