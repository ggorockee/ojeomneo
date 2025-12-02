"""
Menu, Sketch, Recommendation Admin 설정.

Django Unfold를 사용하여 모던한 UI 제공.
"""

from django.contrib import admin
from unfold.admin import ModelAdmin

from .models import Menu, Recommendation, Sketch


@admin.register(Menu)
class MenuAdmin(ModelAdmin):
    """메뉴 Admin"""

    list_display = ["name", "category", "is_active", "tag_count", "created_at"]
    list_filter = ["category", "is_active"]
    search_fields = ["name", "emotion_tags", "situation_tags", "attribute_tags"]
    readonly_fields = ["created_at", "updated_at", "deleted_at"]
    ordering = ["name"]

    fieldsets = [
        (
            "기본 정보",
            {
                "fields": ["name", "category", "image_url", "is_active"],
            },
        ),
        (
            "태그",
            {
                "fields": ["emotion_tags", "situation_tags", "attribute_tags"],
            },
        ),
        (
            "시스템 정보",
            {
                "fields": ["created_at", "updated_at", "deleted_at"],
                "classes": ["collapse"],
            },
        ),
    ]

    def tag_count(self, obj):
        """태그 개수"""
        return len(obj.all_tags)

    tag_count.short_description = "태그 수"


@admin.register(Sketch)
class SketchAdmin(ModelAdmin):
    """스케치 Admin"""

    list_display = ["id", "device_id_short", "user", "emotion", "mood", "created_at"]
    list_filter = ["created_at"]
    search_fields = ["id", "device_id", "input_text"]
    readonly_fields = ["id", "device_id", "user", "image_path", "input_text", "analysis_result", "created_at"]
    ordering = ["-created_at"]

    fieldsets = [
        (
            "기본 정보",
            {
                "fields": ["id", "device_id", "user"],
            },
        ),
        (
            "스케치 데이터",
            {
                "fields": ["image_path", "input_text"],
            },
        ),
        (
            "분석 결과",
            {
                "fields": ["analysis_result"],
            },
        ),
        (
            "시스템 정보",
            {
                "fields": ["created_at"],
                "classes": ["collapse"],
            },
        ),
    ]

    def device_id_short(self, obj):
        """디바이스 ID 축약"""
        return f"{obj.device_id[:12]}..."

    device_id_short.short_description = "디바이스 ID"

    def has_add_permission(self, request):
        """스케치는 API를 통해서만 생성"""
        return False


@admin.register(Recommendation)
class RecommendationAdmin(ModelAdmin):
    """추천 Admin"""

    list_display = ["id", "sketch_id_short", "menu", "rank", "reason_short", "created_at"]
    list_filter = ["rank", "created_at"]
    search_fields = ["sketch__id", "menu__name", "reason"]
    readonly_fields = ["sketch", "menu", "reason", "rank", "created_at"]
    ordering = ["-created_at", "rank"]

    fieldsets = [
        (
            "추천 정보",
            {
                "fields": ["sketch", "menu", "rank", "reason"],
            },
        ),
        (
            "시스템 정보",
            {
                "fields": ["created_at"],
                "classes": ["collapse"],
            },
        ),
    ]

    def sketch_id_short(self, obj):
        """스케치 ID 축약"""
        return str(obj.sketch.id)[:8] + "..."

    sketch_id_short.short_description = "스케치 ID"

    def reason_short(self, obj):
        """추천 이유 축약"""
        if len(obj.reason) > 50:
            return obj.reason[:50] + "..."
        return obj.reason

    reason_short.short_description = "추천 이유"

    def has_add_permission(self, request):
        """추천은 API를 통해서만 생성"""
        return False
