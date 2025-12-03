"""
메뉴 이미지 업로드 폼.
"""

from django import forms

from .models import Menu


class MenuImageUploadForm(forms.Form):
    """메뉴 이미지 업로드 폼"""

    menu = forms.ModelChoiceField(
        queryset=Menu.objects.filter(deleted_at__isnull=True),
        label="메뉴",
        widget=forms.Select(attrs={"class": "form-control"}),
    )
    image = forms.ImageField(
        label="이미지 파일",
        help_text="jpg, jpeg, png, gif, webp 형식 (최대 10MB)",
        widget=forms.FileInput(attrs={"class": "form-control", "accept": "image/*"}),
    )
    is_primary = forms.BooleanField(
        label="대표 이미지로 설정",
        required=False,
        initial=False,
        widget=forms.CheckboxInput(attrs={"class": "form-check-input"}),
    )
