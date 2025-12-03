"""
Menu, Sketch, Recommendation Admin 설정.

Django Unfold를 사용하여 모던한 UI 제공.
"""

from django.contrib import admin
from django.urls import reverse
from django.utils.html import format_html
from unfold.admin import ModelAdmin, TabularInline

from .models import Menu, MenuImage, Recommendation, Sketch


class MenuImageInline(TabularInline):
    """메뉴 이미지 인라인"""

    model = MenuImage
    extra = 0
    fields = ["image_preview", "image_id", "image_url", "is_primary", "sort_order"]
    readonly_fields = ["image_preview", "image_id", "image_url"]

    def image_preview(self, obj):
        """이미지 미리보기"""
        if obj.image_url:
            return format_html(
                '<img src="{}" style="max-width: 100px; max-height: 100px; object-fit: cover;" />',
                obj.thumbnail_url or obj.image_url,
            )
        return "-"

    image_preview.short_description = "미리보기"


@admin.register(Menu)
class MenuAdmin(ModelAdmin):
    """메뉴 Admin"""

    list_display = ["name", "category", "is_active", "image_count", "tag_count", "created_at"]
    list_filter = ["category", "is_active"]
    search_fields = ["name", "emotion_tags", "situation_tags", "attribute_tags"]
    readonly_fields = ["created_at", "updated_at", "deleted_at", "primary_image_preview"]
    ordering = ["name"]
    inlines = [MenuImageInline]

    fieldsets = [
        (
            "기본 정보",
            {
                "fields": ["name", "category", "is_active", "primary_image_preview"],
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

    def image_count(self, obj):
        """이미지 개수"""
        return obj.images.count()

    image_count.short_description = "이미지 수"

    def primary_image_preview(self, obj):
        """대표 이미지 미리보기"""
        primary = obj.images.filter(is_primary=True).first()
        if primary and primary.image_url:
            return format_html(
                '<img src="{}" style="max-width: 200px; max-height: 200px; object-fit: cover;" />',
                primary.thumbnail_url or primary.image_url,
            )
        return "대표 이미지 없음"

    primary_image_preview.short_description = "대표 이미지"


@admin.register(MenuImage)
class MenuImageAdmin(ModelAdmin):
    """메뉴 이미지 Admin"""

    list_display = ["id", "menu", "image_preview_small", "is_primary", "sort_order", "created_at"]
    list_filter = ["is_primary", "menu__category"]
    search_fields = ["menu__name", "image_id"]
    readonly_fields = ["image_id", "image_url", "image_preview", "created_at", "updated_at"]
    ordering = ["-created_at"]
    autocomplete_fields = ["menu"]

    fieldsets = [
        (
            "메뉴 연결",
            {
                "fields": ["menu"],
            },
        ),
        (
            "이미지 정보",
            {
                "fields": ["image_preview", "image_id", "image_url"],
            },
        ),
        (
            "설정",
            {
                "fields": ["is_primary", "sort_order"],
            },
        ),
        (
            "시스템 정보",
            {
                "fields": ["created_at", "updated_at"],
                "classes": ["collapse"],
            },
        ),
    ]

    def changelist_view(self, request, extra_context=None):
        """목록 뷰에 업로드 버튼 추가"""
        extra_context = extra_context or {}
        extra_context["upload_url"] = reverse("menus:upload_image")
        return super().changelist_view(request, extra_context=extra_context)

    def has_add_permission(self, request):
        """기본 추가 버튼 비활성화 (업로드 버튼 사용)"""
        return False

    def image_preview(self, obj):
        """이미지 미리보기 (상세)"""
        if obj.image_url:
            return format_html(
                '<img src="{}" style="max-width: 300px; max-height: 300px; object-fit: cover;" />',
                obj.image_url,
            )
        return "-"

    image_preview.short_description = "이미지 미리보기"

    def image_preview_small(self, obj):
        """이미지 미리보기 (목록)"""
        if obj.image_url:
            return format_html(
                '<img src="{}" style="max-width: 50px; max-height: 50px; object-fit: cover;" />',
                obj.thumbnail_url or obj.image_url,
            )
        return "-"

    image_preview_small.short_description = "이미지"


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
