/// 인증 응답 모델
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final UserResponse user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      user: UserResponse.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'user': user.toJson(),
    };
  }
}

/// 사용자 응답 모델
class UserResponse {
  final int id;
  final String email;
  final String? name;
  final String? profileImage;
  final bool isActive;
  final DateTime dateJoined;
  final String loginMethod;

  UserResponse({
    required this.id,
    required this.email,
    this.name,
    this.profileImage,
    required this.isActive,
    required this.dateJoined,
    required this.loginMethod,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String?,
      profileImage: json['profile_image'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      dateJoined: DateTime.parse(json['date_joined'] as String),
      loginMethod: json['login_method'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (name != null) 'name': name,
      if (profileImage != null) 'profile_image': profileImage,
      'is_active': isActive,
      'date_joined': dateJoined.toIso8601String(),
      'login_method': loginMethod,
    };
  }
}


