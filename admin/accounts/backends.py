"""
Custom Authentication Backends for Ojeomneo.
"""

from django.contrib.auth import get_user_model
from django.contrib.auth.backends import ModelBackend

from .models import LoginMethod

User = get_user_model()


class EmailAuthBackend(ModelBackend):
    """
    이메일 + 비밀번호로 로그인하는 Authentication Backend.

    Django Admin과 일반 로그인에서 email을 사용할 수 있게 합니다.
    login_method=email인 사용자만 이 방식으로 인증됩니다.
    """

    def authenticate(self, request, username=None, password=None, **kwargs):
        """
        username 파라미터에 email이 들어옵니다.
        email + login_method=email 조합으로 사용자를 찾아 인증합니다.
        """
        email = kwargs.get("email") or username

        if email is None or password is None:
            return None

        try:
            user = User.objects.get(email=email, login_method=LoginMethod.EMAIL)
        except User.DoesNotExist:
            # 타이밍 공격 방지를 위해 패스워드 해싱 수행
            User().set_password(password)
            return None
        except User.MultipleObjectsReturned:
            # 같은 email + email 로그인 방식이 여러 개면 첫 번째 반환
            user = User.objects.filter(email=email, login_method=LoginMethod.EMAIL).first()
            if user is None:
                return None

        if user.check_password(password) and self.user_can_authenticate(user):
            return user

        return None

    def get_user(self, user_id):
        """사용자 ID로 사용자 조회"""
        try:
            return User.objects.get(pk=user_id)
        except User.DoesNotExist:
            return None
