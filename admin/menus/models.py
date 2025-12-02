"""
Menu, Sketch, Recommendation 모델.

Go GORM이 스키마를 관리하고, Django는 읽기/쓰기만 수행합니다.
managed=False로 설정하여 Django가 테이블을 생성/수정하지 않습니다.

Server 모델과 동기화 필요:
- server/internal/model/menu.go
- server/internal/model/sketch.go
- server/internal/model/recommendation.go
"""

import uuid

from django.db import models

from accounts.models import User


class MenuCategory(models.TextChoices):
    """메뉴 카테고리"""

    KOREAN = "korean", "한식"
    CHINESE = "chinese", "중식"
    JAPANESE = "japanese", "일식"
    WESTERN = "western", "양식"
    ASIAN = "asian", "아시안"
    SNACK = "snack", "분식"
    CAFE = "cafe", "카페/디저트"
    OTHER = "other", "기타"


class Menu(models.Model):
    """
    메뉴 모델.

    Go GORM Menu 테이블과 호환.
    managed=False: Django가 테이블을 생성/수정하지 않음 (Go GORM이 관리)
    """

    id = models.BigAutoField(primary_key=True)
    name = models.CharField("메뉴명", max_length=100, unique=True)
    category = models.CharField(
        "카테고리",
        max_length=50,
        choices=MenuCategory.choices,
        default=MenuCategory.OTHER,
    )
    image_url = models.TextField("이미지 URL", blank=True, default="")

    # 태그 (JSONB로 저장 - PostgreSQL)
    emotion_tags = models.JSONField("감정 태그", default=list)
    situation_tags = models.JSONField("상황 태그", default=list)
    attribute_tags = models.JSONField("속성 태그", default=list)

    is_active = models.BooleanField("활성화", default=True)

    # GORM 타임스탬프 필드
    created_at = models.DateTimeField("생성일", auto_now_add=True)
    updated_at = models.DateTimeField("수정일", auto_now=True)
    deleted_at = models.DateTimeField("삭제일", blank=True, null=True)

    class Meta:
        db_table = "menus"
        managed = False
        verbose_name = "메뉴"
        verbose_name_plural = "메뉴"
        ordering = ["name"]

    def __str__(self):
        return f"{self.name} ({self.get_category_display()})"

    @property
    def all_tags(self):
        """모든 태그를 하나의 리스트로 반환"""
        return (self.emotion_tags or []) + (self.situation_tags or []) + (self.attribute_tags or [])


class Sketch(models.Model):
    """
    스케치 모델.

    Go GORM Sketch 테이블과 호환.
    managed=False: Django가 테이블을 생성/수정하지 않음 (Go GORM이 관리)
    """

    id = models.UUIDField("ID", primary_key=True, default=uuid.uuid4)
    device_id = models.CharField("디바이스 ID", max_length=255, db_index=True)
    user = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        verbose_name="사용자",
        related_name="sketches",
    )
    image_path = models.TextField("이미지 경로")
    input_text = models.TextField("입력 텍스트", blank=True, default="")

    # LLM 분석 결과 (JSONB)
    analysis_result = models.JSONField("분석 결과", blank=True, null=True)

    # GORM 타임스탬프 필드
    created_at = models.DateTimeField("생성일", auto_now_add=True)
    deleted_at = models.DateTimeField("삭제일", blank=True, null=True)

    class Meta:
        db_table = "sketches"
        managed = False
        verbose_name = "스케치"
        verbose_name_plural = "스케치"
        ordering = ["-created_at"]

    def __str__(self):
        return f"Sketch {self.id} ({self.device_id[:8]}...)"

    @property
    def emotion(self):
        """분석 결과에서 감정 추출"""
        if self.analysis_result:
            return self.analysis_result.get("emotion", "")
        return ""

    @property
    def keywords(self):
        """분석 결과에서 키워드 추출"""
        if self.analysis_result:
            return self.analysis_result.get("keywords", [])
        return []

    @property
    def mood(self):
        """분석 결과에서 무드 추출"""
        if self.analysis_result:
            return self.analysis_result.get("mood", "")
        return ""


class Recommendation(models.Model):
    """
    추천 모델.

    Go GORM Recommendation 테이블과 호환.
    managed=False: Django가 테이블을 생성/수정하지 않음 (Go GORM이 관리)
    """

    id = models.BigAutoField(primary_key=True)
    sketch = models.ForeignKey(
        Sketch,
        on_delete=models.CASCADE,
        verbose_name="스케치",
        related_name="recommendations",
    )
    menu = models.ForeignKey(
        Menu,
        on_delete=models.CASCADE,
        verbose_name="메뉴",
        related_name="recommendations",
    )
    reason = models.TextField("추천 이유")
    rank = models.IntegerField("순위", default=1)

    # GORM 타임스탬프 필드
    created_at = models.DateTimeField("생성일", auto_now_add=True)

    class Meta:
        db_table = "recommendations"
        managed = False
        verbose_name = "추천"
        verbose_name_plural = "추천"
        ordering = ["rank"]

    def __str__(self):
        return f"{self.menu.name} (순위: {self.rank})"
