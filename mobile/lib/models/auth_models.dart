/// 인증 관련 모델 클래스들
/// - API 요청/응답 데이터 구조 정의
/// - JSON 직렬화/역직렬화 지원

/// 이메일 인증코드 발송 요청 데이터
class EmailSendCodeRequest {
  final String email;

  EmailSendCodeRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

/// 이메일 인증코드 발송 응답 데이터
class EmailSendCodeResponse {
  final String message;

  EmailSendCodeResponse({required this.message});

  factory EmailSendCodeResponse.fromJson(Map<String, dynamic> json) {
    return EmailSendCodeResponse(
      message: json['message'] as String? ?? '인증코드가 발송되었습니다',
    );
  }
}

/// 이메일 인증코드 확인 요청 데이터
class EmailVerifyCodeRequest {
  final String email;
  final String code;

  EmailVerifyCodeRequest({
    required this.email,
    required this.code,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'code': code,
      };
}

/// 이메일 인증코드 확인 응답 데이터
class EmailVerifyCodeResponse {
  final bool verified;
  final String verificationToken;

  EmailVerifyCodeResponse({
    required this.verified,
    required this.verificationToken,
  });

  factory EmailVerifyCodeResponse.fromJson(Map<String, dynamic> json) {
    return EmailVerifyCodeResponse(
      verified: json['verified'] as bool? ?? false,
      verificationToken: json['verification_token'] as String? ?? '',
    );
  }
}

/// 회원가입 요청 데이터
class SignUpRequest {
  final String email;
  final String password;
  final String? firstName;
  final String? lastName;
  final String verificationToken;

  SignUpRequest({
    required this.email,
    required this.password,
    this.firstName,
    this.lastName,
    required this.verificationToken,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        if (firstName != null && firstName!.isNotEmpty) 'first_name': firstName,
        if (lastName != null && lastName!.isNotEmpty) 'last_name': lastName,
        'verification_token': verificationToken,
      };
}

/// 로그인 요청 데이터
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

/// Refresh Token 요청 데이터
class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => {
        'refresh_token': refreshToken,
      };
}

/// 비밀번호 재설정 요청 데이터
class PasswordResetRequest {
  final String email;

  PasswordResetRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

/// 비밀번호 재설정 인증코드 확인 요청 데이터
class PasswordResetVerifyRequest {
  final String email;
  final String code;

  PasswordResetVerifyRequest({
    required this.email,
    required this.code,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'code': code,
      };
}

/// 비밀번호 재설정 인증코드 확인 응답 데이터
class PasswordResetVerifyResponse {
  final String resetToken;

  PasswordResetVerifyResponse({required this.resetToken});

  factory PasswordResetVerifyResponse.fromJson(Map<String, dynamic> json) {
    return PasswordResetVerifyResponse(
      resetToken: json['reset_token'] as String? ?? '',
    );
  }
}

/// 비밀번호 재설정 확정 요청 데이터
class PasswordResetConfirmRequest {
  final String email;
  final String resetToken;
  final String newPassword;

  PasswordResetConfirmRequest({
    required this.email,
    required this.resetToken,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'reset_token': resetToken,
        'new_password': newPassword,
      };
}

