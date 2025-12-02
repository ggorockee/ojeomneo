"""
User Admin configuration with Django Unfold.
"""

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.forms import UserChangeForm, UserCreationForm
from unfold.admin import ModelAdmin

from .models import LoginMethod, User


class CustomUserCreationForm(UserCreationForm):
    """사용자 생성 폼 - email 필수"""

    class Meta:
        model = User
        fields = ("email",)


class CustomUserChangeForm(UserChangeForm):
    """사용자 수정 폼"""

    class Meta:
        model = User
        fields = "__all__"


@admin.register(User)
class UserAdmin(BaseUserAdmin, ModelAdmin):
    """Custom User Admin with Unfold styling."""

    form = CustomUserChangeForm
    add_form = CustomUserCreationForm

    list_display = (
        "email",
        "login_method",
        "username",
        "is_staff",
        "is_active",
        "date_joined",
    )
    list_filter = ("login_method", "is_staff", "is_superuser", "is_active")
    search_fields = ("email", "username", "first_name", "last_name")
    ordering = ("-date_joined",)

    fieldsets = (
        (None, {"fields": ("email", "username", "password")}),
        (
            "로그인 정보",
            {
                "fields": ("login_method", "social_id"),
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
            },
        ),
    )

    readonly_fields = ("date_joined", "last_login", "created_at", "updated_at")

    def save_model(self, request, obj, form, change):
        """새 사용자 생성 시 login_method=email로 설정"""
        if not change:
            obj.login_method = LoginMethod.EMAIL
            # username 자동 생성
            if not obj.username:
                import uuid

                base = obj.email.split("@")[0]
                obj.username = f"{base}_{uuid.uuid4().hex[:8]}"
        super().save_model(request, obj, form, change)

    def get_readonly_fields(self, request, obj=None):
        """기존 사용자는 login_method, social_id 수정 불가"""
        readonly = list(super().get_readonly_fields(request, obj))
        if obj:
            readonly.extend(["login_method", "social_id"])
        return readonly
