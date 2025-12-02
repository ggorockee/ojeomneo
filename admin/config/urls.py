"""
URL configuration for config project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""

import time

from django.conf import settings
from django.contrib import admin
from django.db import connection
from django.http import JsonResponse
from django.urls import path


def liveness_check(request):
    """
    Liveness 체크 (Kubernetes startup/liveness probe용)
    서버가 살아있는지 확인 (DB 연결 무관)
    """
    return JsonResponse({
        "status": "ok",
        "service": "ojeomneo-admin",
    })


def readiness_check(request):
    """
    Readiness 체크 (Kubernetes readiness probe용)
    서버가 트래픽을 받을 준비가 됐는지 확인 (DB 연결 포함)
    """
    response = {
        "status": "ok",
        "ready": True,
        "database": False,
    }

    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        response["database"] = True
    except Exception:
        response["status"] = "not_ready"
        response["ready"] = False
        return JsonResponse(response, status=503)

    return JsonResponse(response)


def health_check(request):
    """
    서버 상세 헬스체크 (모니터링/디버깅용)
    서버 및 데이터베이스 상태 상세 확인
    """
    response = {
        "status": "ok",
        "service": "ojeomneo-admin",
        "version": settings.APP_VERSION,
        "database": {
            "connected": False,
            "latency_ms": 0,
            "message": "",
        },
    }

    try:
        start = time.time()
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        latency_ms = int((time.time() - start) * 1000)

        response["database"] = {
            "connected": True,
            "latency_ms": latency_ms,
            "message": "Database connection successful",
        }
    except Exception as e:
        response["status"] = "degraded"
        response["database"] = {
            "connected": False,
            "latency_ms": 0,
            "message": f"Database connection failed: {e!s}",
        }

    return JsonResponse(response)


urlpatterns = [
    # Health check 엔드포인트
    path("ojeomneo/v1/healthcheck/", health_check, name="healthcheck"),
    path("ojeomneo/v1/healthcheck/live/", liveness_check, name="liveness"),
    path("ojeomneo/v1/healthcheck/ready/", readiness_check, name="readiness"),
    # Admin
    path("ojeomneo/v1/admin/", admin.site.urls),
]
