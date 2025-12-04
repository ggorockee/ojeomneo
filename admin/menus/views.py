"""
메뉴 이미지 업로드 뷰.

Server API를 호출하여 Cloudflare Images에 업로드하고 결과를 DB에 저장합니다.
"""

import logging
import traceback

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
    logger.info(f"upload_menu_image called: method={request.method}")

    if request.method == "POST":
        logger.info("Processing POST request for image upload")
        form = MenuImageUploadForm(request.POST, request.FILES)

        if not form.is_valid():
            logger.warning(f"Form validation failed: {form.errors}")
            messages.error(request, f"폼 검증 실패: {form.errors}")
            return render(request, "admin/menus/upload_image.html", {"form": form, "title": "메뉴 이미지 업로드"})

        menu = form.cleaned_data["menu"]
        image = form.cleaned_data["image"]
        is_primary = form.cleaned_data["is_primary"]

        logger.info(f"Form valid: menu={menu.id}, image={image.name}, is_primary={is_primary}")

        # SERVER_API_URL 설정 확인
        server_api_url = getattr(settings, "SERVER_API_URL", None)
        logger.info(f"SERVER_API_URL: {server_api_url}")

        if not server_api_url:
            messages.error(request, "SERVER_API_URL이 설정되지 않았습니다.")
            logger.error("SERVER_API_URL not configured")
            return render(request, "admin/menus/upload_image.html", {"form": form, "title": "메뉴 이미지 업로드"})

        # Server API에 이미지 업로드
        try:
            api_url = f"{server_api_url}/images/upload"
            logger.info(f"Uploading image to: {api_url}")

            # 파일 읽기 전 위치 확인
            image.seek(0)
            file_content = image.read()
            logger.info(f"Image size: {len(file_content)} bytes, content_type: {image.content_type}")

            files = {"file": (image.name, file_content, image.content_type)}
            data = {"type": "menu"}

            response = requests.post(api_url, files=files, data=data, timeout=30)
            logger.info(f"Server response: status={response.status_code}")

            try:
                result = response.json()
                logger.info(f"Response JSON: {result}")
            except ValueError as json_err:
                logger.error(f"Failed to parse JSON response: {json_err}, raw={response.text[:500]}")
                messages.error(request, f"서버 응답 파싱 오류: {response.text[:200]}")
                return render(request, "admin/menus/upload_image.html", {"form": form, "title": "메뉴 이미지 업로드"})

            if response.status_code == 200 and result.get("success"):
                image_data = result["data"]
                logger.info(f"Upload successful: id={image_data.get('id')}, url={image_data.get('url')}")

                # 대표 이미지로 설정하는 경우 기존 대표 이미지 해제
                if is_primary:
                    updated = MenuImage.objects.filter(menu=menu, is_primary=True).update(is_primary=False)
                    logger.info(f"Reset {updated} existing primary images")

                # DB에 저장
                menu_image = MenuImage.objects.create(
                    menu=menu,
                    image_id=image_data["id"],
                    image_url=image_data["url"],
                    is_primary=is_primary,
                    sort_order=MenuImage.objects.filter(menu=menu).count(),
                )
                logger.info(f"MenuImage created: id={menu_image.id}")

                messages.success(request, f"이미지가 성공적으로 업로드되었습니다. (ID: {menu_image.id})")
                return redirect("admin:menus_menuimage_changelist")
            else:
                error_msg = result.get("error", result.get("message", "알 수 없는 오류"))
                messages.error(request, f"업로드 실패: {error_msg}")
                logger.error(f"Upload failed: status={response.status_code}, error={error_msg}")

        except requests.Timeout:
            messages.error(request, "서버 응답 시간 초과 (30초)")
            logger.error("Request timeout after 30 seconds")
        except requests.ConnectionError as e:
            messages.error(request, f"서버 연결 실패: {e}")
            logger.error(f"Connection error: {e}")
        except requests.RequestException as e:
            messages.error(request, f"서버 요청 오류: {e}")
            logger.exception(f"Request error: {e}")
        except Exception as e:
            messages.error(request, f"업로드 중 오류 발생: {e}")
            logger.error(f"Unexpected error: {e}\n{traceback.format_exc()}")

        return render(request, "admin/menus/upload_image.html", {"form": form, "title": "메뉴 이미지 업로드"})

    else:
        # GET 요청 시 menu_id 파라미터가 있으면 초기값 설정
        initial = {}
        menu_id = request.GET.get("menu_id")
        if menu_id:
            initial["menu"] = menu_id
            logger.info(f"Pre-selecting menu_id: {menu_id}")
        form = MenuImageUploadForm(initial=initial)

    return render(request, "admin/menus/upload_image.html", {"form": form, "title": "메뉴 이미지 업로드"})
