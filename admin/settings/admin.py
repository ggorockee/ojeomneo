"""
AppVersion Admin 설정.

Django Unfold를 사용하여 모던한 UI 제공.
"""

from django.contrib import admin
from unfold.admin import ModelAdmin

from .models import AppVersion


@admin.register(AppVersion)
class AppVersionAdmin(ModelAdmin):
    """앱 버전 Admin"""

    list_display = ["platform", "latest_version", "min_version", "force_update", "is_active", "updated_at"]
    list_filter = ["platform", "force_update", "is_active"]
    search_fields = ["platform", "latest_version", "min_version"]
    readonly_fields = ["updated_at"]
    ordering = ["platform"]

    fieldsets = [
        (
            "플랫폼 정보",
            {
                "fields": ["platform", "is_active"],
            },
        ),
        (
            "버전 설정",
            {
                "fields": ["latest_version", "min_version", "force_update"],
                "description": "최소 버전보다 낮은 앱은 강제 업데이트 팝업이 표시됩니다.",
            },
        ),
        (
            "스토어 정보",
            {
                "fields": ["store_url", "update_message"],
            },
        ),
        (
            "시스템 정보",
            {
                "fields": ["updated_at"],
                "classes": ["collapse"],
            },
        ),
    ]
