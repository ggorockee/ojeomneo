"""
메뉴 URL 패턴.
"""

from django.urls import path

from . import views

app_name = "menus"

urlpatterns = [
    path("upload-image/", views.upload_menu_image, name="upload_image"),
]
