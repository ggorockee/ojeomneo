"""
메뉴 이미지 업로드 뷰.

Server API를 호출하여 Cloudflare Images에 업로드하고 결과를 DB에 저장합니다.
"""

import logging

import requests
from django.conf import settings
from django.contrib import messages
from django.contrib.admin.views.decorators import staff_member_required
from django.shortcuts import redirect, render

from .forms import MenuImageUploadForm
from .models import MenuImage

logger = logging.getLogger(__name__)


@staff_member_required
def upload_menu_image(request):
    """메뉴 이미지 업로드 뷰"""
    if request.method == "POST":
        form = MenuImageUploadForm(request.POST, request.FILES)
        if form.is_valid():
            menu = form.cleaned_data["menu"]
            image = form.cleaned_data["image"]
            is_primary = form.cleaned_data["is_primary"]

            # SERVER_API_URL 설정 확인
            server_api_url = getattr(settings, "SERVER_API_URL", None)
            if not server_api_url:
                messages.error(request, "SERVER_API_URL이 설정되지 않았습니다.")
                logger.error("SERVER_API_URL not configured")
                return render(request, "admin/menus/upload_image.html", {"form": form, "title": "메뉴 이미지 업로드"})

            # Server API에 이미지 업로드
            try:
                api_url = f"{server_api_url}/images/upload"
                files = {"file": (image.name, image.read(), image.content_type)}
                data = {"type": "menu"}

                logger.info(f"Uploading image to {api_url}")
                response = requests.post(api_url, files=files, data=data, timeout=30)
                result = response.json()

                if response.status_code == 200 and result.get("success"):
                    image_data = result["data"]

                    # 대표 이미지로 설정하는 경우 기존 대표 이미지 해제
                    if is_primary:
                        MenuImage.objects.filter(menu=menu, is_primary=True).update(is_primary=False)

                    # DB에 저장
                    menu_image = MenuImage.objects.create(
                        menu=menu,
                        image_id=image_data["id"],
                        image_url=image_data["url"],
                        is_primary=is_primary,
                        sort_order=MenuImage.objects.filter(menu=menu).count(),
                    )

                    messages.success(request, f"이미지가 성공적으로 업로드되었습니다. (ID: {menu_image.id})")
                    return redirect("admin:menus_menuimage_changelist")
                else:
                    error_msg = result.get("error", "알 수 없는 오류")
                    messages.error(request, f"업로드 실패: {error_msg}")
                    logger.error(f"Upload failed: {error_msg}")

            except requests.RequestException as e:
                messages.error(request, f"서버 연결 오류: {e}")
                logger.exception(f"Request error: {e}")
            except Exception as e:
                messages.error(request, f"업로드 중 오류 발생: {e}")
                logger.exception(f"Upload error: {e}")
    else:
        # GET 요청 시 menu_id 파라미터가 있으면 초기값 설정
        initial = {}
        menu_id = request.GET.get("menu_id")
        if menu_id:
            initial["menu"] = menu_id
        form = MenuImageUploadForm(initial=initial)

    return render(request, "admin/menus/upload_image.html", {"form": form, "title": "메뉴 이미지 업로드"})
