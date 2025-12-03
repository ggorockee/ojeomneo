"""
AppVersion 모델.

Go GORM이 스키마를 관리하고, Django는 읽기/쓰기만 수행합니다.
managed=False로 설정하여 Django가 테이블을 생성/수정하지 않습니다.

Server 모델과 동기화 필요:
- server/internal/model/app_version.go
"""

from django.db import models


class Platform(models.TextChoices):
    """플랫폼 타입"""

    IOS = "ios", "iOS"
    ANDROID = "android", "Android"


class AppVersion(models.Model):
    """
    앱 버전 관리 모델.

    Go GORM AppVersion 테이블과 호환.
    managed=False: Django가 테이블을 생성/수정하지 않음 (Go GORM이 관리)
    """

    id = models.BigAutoField(primary_key=True)
    platform = models.CharField(
        "플랫폼",
        max_length=20,
        choices=Platform.choices,
        unique=True,
    )
    min_version = models.CharField("최소 버전", max_length=20)
    latest_version = models.CharField("최신 버전", max_length=20)
    force_update = models.BooleanField("강제 업데이트", default=False)
    store_url = models.TextField("스토어 URL", blank=True, default="")
    update_message = models.TextField("업데이트 메시지", blank=True, default="")
    is_active = models.BooleanField("활성화", default=True)

    # GORM 타임스탬프 필드
    updated_at = models.DateTimeField("수정일", auto_now=True)
    updated_by = models.BigIntegerField("수정자 ID", blank=True, null=True)

    class Meta:
        db_table = "app_versions"
        managed = False
        verbose_name = "앱 버전"
        verbose_name_plural = "앱 버전"
        ordering = ["platform"]

    def __str__(self):
        return f"{self.get_platform_display()} - v{self.latest_version}"
