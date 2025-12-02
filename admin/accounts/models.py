"""
Custom User Model for Ojeomneo.

SNS 로그인(카카오, 구글, 애플)과 이메일 로그인을 모두 지원합니다.
같은 이메일로 여러 로그인 방식을 사용할 수 있습니다.
"""

import uuid

from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.db import models


class LoginMethod(models.TextChoices):
    """로그인 방식"""

    EMAIL = "email", "이메일"
    KAKAO = "kakao", "카카오"
    GOOGLE = "google", "구글"
    APPLE = "apple", "애플"


class UserManager(BaseUserManager):
    """
    Email + LoginMethod 기반 User Manager.
    """

    def _generate_username(self, email, login_method, social_id=None):
        """
        고유한 username 생성.
        - email 로그인: email의 @ 앞부분 + uuid 일부
        - SNS 로그인: {provider}_{social_id} 또는 {provider}_{uuid}
        """
        if login_method == LoginMethod.EMAIL:
            base = email.split("@")[0]
            return f"{base}_{uuid.uuid4().hex[:8]}"
        else:
            if social_id:
                return f"{login_method}_{social_id}"
            return f"{login_method}_{uuid.uuid4().hex[:8]}"

    def create_user(self, email, password=None, login_method=LoginMethod.EMAIL, **extra_fields):
        """일반 사용자 생성"""
        if not email:
            raise ValueError("이메일은 필수입니다.")

        email = self.normalize_email(email)
        social_id = extra_fields.pop("social_id", None)

        # username 자동 생성
        if not extra_fields.get("username"):
            extra_fields["username"] = self._generate_username(email, login_method, social_id)

        user = self.model(
            email=email,
            login_method=login_method,
            social_id=social_id or "",
            **extra_fields,
        )

        # SNS 로그인은 password 없이 가능
        if password:
            user.set_password(password)
        else:
            user.set_unusable_password()

        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        """관리자 생성 (이메일 로그인만 가능)"""
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)

        if extra_fields.get("is_staff") is not True:
            raise ValueError("Superuser must have is_staff=True.")
        if extra_fields.get("is_superuser") is not True:
            raise ValueError("Superuser must have is_superuser=True.")

        return self.create_user(
            email,
            password,
            login_method=LoginMethod.EMAIL,
            **extra_fields,
        )

    def get_by_natural_key(self, email):
        """이메일로 사용자 조회 (기본 로그인용)"""
        return self.get(email=email, login_method=LoginMethod.EMAIL)


class User(AbstractUser):
    """
    Email + LoginMethod 기반 Custom User Model.

    같은 이메일로 여러 로그인 방식 사용 가능:
    - woohaen88@gmail.com + email (이메일 로그인)
    - woohaen88@gmail.com + kakao (카카오 로그인)
    - woohaen88@gmail.com + google (구글 로그인)
    - woohaen88@gmail.com + apple (애플 로그인)
    """

    email = models.EmailField("이메일")  # unique 제거 (복합키로 관리)

    login_method = models.CharField(
        "로그인 방식",
        max_length=20,
        choices=LoginMethod.choices,
        default=LoginMethod.EMAIL,
    )

    social_id = models.CharField(
        "소셜 ID",
        max_length=255,
        blank=True,
        default="",
        help_text="SNS provider에서 제공하는 고유 사용자 ID",
    )

    # Django 기본 인증에서 username 사용 (자동 생성됨)
    USERNAME_FIELD = "username"
    REQUIRED_FIELDS = ["email"]

    objects = UserManager()

    class Meta:
        db_table = "users"
        verbose_name = "사용자"
        verbose_name_plural = "사용자"
        constraints = [
            # 같은 이메일 + 같은 로그인방식 조합은 중복 불가
            models.UniqueConstraint(
                fields=["email", "login_method"],
                name="unique_email_login_method",
            ),
        ]

    def __str__(self):
        if self.login_method == LoginMethod.EMAIL:
            return self.email
        return f"{self.email} ({self.get_login_method_display()})"

    @property
    def is_social_user(self):
        """SNS 로그인 사용자 여부"""
        return self.login_method != LoginMethod.EMAIL
