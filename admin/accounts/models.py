"""
Custom User Model for Ojeomneo.

Go GORM이 스키마를 관리하고, Django는 읽기/쓰기만 수행합니다.
managed=False로 설정하여 Django가 테이블을 생성/수정하지 않습니다.
"""

from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
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

    def create_user(self, email, password=None, login_method=LoginMethod.EMAIL, **extra_fields):
        """일반 사용자 생성"""
        if not email:
            raise ValueError("이메일은 필수입니다.")

        email = self.normalize_email(email)

        # username 자동 생성
        if not extra_fields.get("username"):
            import uuid

            if login_method == LoginMethod.EMAIL:
                base = email.split("@")[0]
                extra_fields["username"] = f"{base}_{uuid.uuid4().hex[:8]}"
            else:
                social_id = extra_fields.get("social_id", "")
                if social_id:
                    extra_fields["username"] = f"{login_method}_{social_id}"
                else:
                    extra_fields["username"] = f"{login_method}_{uuid.uuid4().hex[:8]}"

        user = self.model(
            email=email,
            login_method=login_method,
            **extra_fields,
        )

        if password:
            user.set_password(password)
        else:
            user.set_unusable_password()

        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        """관리자 생성"""
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        extra_fields.setdefault("is_active", True)

        if extra_fields.get("is_staff") is not True:
            raise ValueError("Superuser must have is_staff=True.")
        if extra_fields.get("is_superuser") is not True:
            raise ValueError("Superuser must have is_superuser=True.")

        return self.create_user(email, password, LoginMethod.EMAIL, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    """
    Go GORM User 테이블과 호환되는 Django User 모델.

    managed=False: Django가 테이블을 생성/수정하지 않음 (Go GORM이 관리)

    같은 이메일로 여러 로그인 방식 사용 가능:
    - woohaen88@gmail.com + email
    - woohaen88@gmail.com + kakao
    - woohaen88@gmail.com + google
    - woohaen88@gmail.com + apple
    """

    # Go GORM 필드와 매핑
    id = models.BigAutoField(primary_key=True)
    password = models.CharField("비밀번호", max_length=128)
    last_login = models.DateTimeField("마지막 로그인", blank=True, null=True)
    is_superuser = models.BooleanField("슈퍼유저 여부", default=False)
    username = models.CharField("사용자명", max_length=150, unique=True)

    # PermissionsMixin의 groups와 user_permissions 필드 제거
    # Go GORM이 이런 중간 테이블을 생성하지 않으므로 Django에서도 사용하지 않음
    groups = None
    user_permissions = None
    first_name = models.CharField("이름", max_length=150, blank=True, default="")
    last_name = models.CharField("성", max_length=150, blank=True, default="")
    email = models.EmailField("이메일", max_length=254)
    is_staff = models.BooleanField("스태프 여부", default=False)
    is_active = models.BooleanField("활성화 여부", default=True)
    date_joined = models.DateTimeField("가입일", auto_now_add=True)

    # SNS 로그인 지원 필드
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
    )

    # GORM 타임스탬프 필드
    created_at = models.DateTimeField("생성일", auto_now_add=True)
    updated_at = models.DateTimeField("수정일", auto_now=True)
    deleted_at = models.DateTimeField("삭제일", blank=True, null=True)

    USERNAME_FIELD = "username"
    EMAIL_FIELD = "email"
    REQUIRED_FIELDS = ["email"]

    objects = UserManager()

    class Meta:
        db_table = "users"
        managed = False  # Go GORM이 테이블 관리
        verbose_name = "사용자"
        verbose_name_plural = "사용자"

    def __str__(self):
        if self.login_method == LoginMethod.EMAIL:
            return self.email
        return f"{self.email} ({self.get_login_method_display()})"

    @property
    def is_social_user(self):
        """SNS 로그인 사용자 여부"""
        return self.login_method != LoginMethod.EMAIL
