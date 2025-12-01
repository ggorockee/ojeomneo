"""
Custom User Model for Ojeomneo.
"""

from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    """
    Custom User Model.

    Django 기본 User를 확장하여 추가 필드를 정의할 수 있습니다.
    Go API와 동일한 테이블을 공유합니다.
    """

    # 추가 필드 예시 (필요 시 활성화)
    # phone = models.CharField("전화번호", max_length=20, blank=True)
    # profile_image = models.URLField("프로필 이미지", blank=True)

    class Meta:
        db_table = "users"  # Go GORM과 테이블명 일치
        verbose_name = "사용자"
        verbose_name_plural = "사용자"

    def __str__(self):
        return self.username
