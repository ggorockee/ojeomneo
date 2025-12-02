"""
User Admin configuration with Django Unfold.
"""

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from unfold.admin import ModelAdmin

from .models import LoginMethod, User


@admin.register(User)
class UserAdmin(BaseUserAdmin, ModelAdmin):
    """Custom User Admin with Unfold styling."""

    list_display = (
        "email",
        "login_method",
        "username",
        "is_staff",
        "is_active",
        "date_joined",
    )
    list_filter = ("login_method", "is_staff", "is_superuser", "is_active", "groups")
    search_fields = ("email", "username", "first_name", "last_name")
    ordering = ("-date_joined",)

    fieldsets = (
        (None, {"fields": ("email", "username", "password")}),
        (
            "로그인 정보",
            {
                "fields": ("login_method", "social_id"),
                "description": "SNS 로그인 사용자의 경우 로그인 방식과 소셜 ID가 표시됩니다.",
            },
        ),
        ("개인 정보", {"fields": ("first_name", "last_name")}),
        (
            "권한",
            {"fields": ("is_active", "is_staff", "is_superuser", "groups", "user_permissions")},
        ),
        ("중요 일자", {"fields": ("last_login", "date_joined")}),
    )

    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": ("email", "password1", "password2"),
                "description": "이메일과 비밀번호를 입력하세요. username은 자동 생성됩니다.",
            },
        ),
    )

    readonly_fields = ("date_joined", "last_login")

    def save_model(self, request, obj, form, change):
        """새 사용자 생성 시 login_method=email로 설정"""
        if not change:  # 새로 생성하는 경우
            obj.login_method = LoginMethod.EMAIL
        super().save_model(request, obj, form, change)

    def get_readonly_fields(self, request, obj=None):
        """기존 사용자는 login_method, social_id 수정 불가"""
        readonly = list(super().get_readonly_fields(request, obj))
        if obj:  # 기존 사용자 수정 시
            readonly.extend(["login_method", "social_id"])
        return readonly
