"""
V1 API Router aggregation.
Combines all v1 API endpoints.
"""
from ninja import NinjaAPI
from api.v1.healthcheck import router as healthcheck_router

# Create NinjaAPI instance with v1 prefix
api = NinjaAPI(version="1.0.0", title="Ojeomneo API", description="오점너 (오늘 점심 뭐 먹을래?) API")

# Register routers
api.add_router("", healthcheck_router)
