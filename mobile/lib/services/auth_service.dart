import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/auth_response.dart';
import '../models/auth_models.dart';
import '../config/app_config.dart';
import 'api_service.dart';

/// 인증 서비스
/// 
/// SNS 로그인 플로우를 처리하고 토큰을 안전하게 저장합니다.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  // Google Sign In 인스턴스
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _profileImageKey = 'profile_image';

  /// Google 로그인 플로우
  ///
  /// 1. google_sign_in으로 Google 로그인 수행
  /// 2. Firebase Auth로 GoogleAuthProvider를 사용하여 로그인
  /// 3. Firebase ID Token 획득
  /// 4. 백엔드 API 호출하여 JWT 토큰 획득
  /// 5. 토큰 저장
  Future<AuthResponse> loginWithGoogle() async {
    try {
      debugPrint('[AuthService] Google 로그인 시작');

      // 1. Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[AuthService] 사용자가 Google 로그인을 취소함');
        throw Exception('LOGIN_CANCELED');
      }

      debugPrint('[AuthService] Google 계정 정보 획득: ${googleUser.email}');

      // 2. Google Sign In Authentication 획득
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // 3. Firebase Auth로 로그인 (GoogleAuthProvider 사용)
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Firebase 인증에 실패했습니다.');
      }

      debugPrint('[AuthService] Firebase 로그인 완료: ${firebaseUser.email}');

      // 4. Firebase ID Token 획득
      final String? idToken = await firebaseUser.getIdToken();
      if (idToken == null) {
        throw Exception('ID Token을 가져올 수 없습니다.');
      }

      debugPrint('[AuthService] Firebase ID Token 획득 완료');

      // 5. 백엔드 API 호출
      final responseData = await _apiService.postSNSLogin(
        provider: 'google',
        token: idToken,
      );

      final authResponse = AuthResponse.fromJson(responseData);
      debugPrint('[AuthService] 백엔드 인증 완료: ${authResponse.user.email}');

      // 6. 토큰 및 사용자 정보 저장
      await _saveTokens(authResponse);

      // Google 프로필 이미지 저장 (Firebase User의 photoURL 사용)
      if (firebaseUser.photoURL != null && firebaseUser.photoURL!.isNotEmpty) {
        await _storage.write(key: _profileImageKey, value: firebaseUser.photoURL);
        debugPrint('[AuthService] Google 프로필 이미지 저장: ${firebaseUser.photoURL}');
      }

      return authResponse;
    } catch (e, stackTrace) {
      debugPrint('[AuthService] Google 로그인 실패: $e');
      debugPrint('[AuthService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Apple 로그인 플로우 (iOS 전용)
  /// 
  /// 1. sign_in_with_apple으로 Apple 로그인 수행
  /// 2. Identity Token 획득
  /// 3. 백엔드 API 호출하여 JWT 토큰 획득
  /// 4. 토큰 저장
  Future<AuthResponse> loginWithApple() async {
    if (!Platform.isIOS) {
      throw Exception('Apple 로그인은 iOS에서만 사용할 수 있습니다.');
    }

    try {
      debugPrint('[AuthService] Apple 로그인 시작');

      // 1. Apple 로그인 수행
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      debugPrint('[AuthService] Apple 계정 정보 획득');

      // 2. Identity Token 확인
      if (credential.identityToken == null) {
        throw Exception('Identity Token을 가져올 수 없습니다.');
      }

      final identityToken = credential.identityToken!;
      debugPrint('[AuthService] Apple Identity Token 획득 완료');

      // 3. 백엔드 API 호출
      final responseData = await _apiService.postSNSLogin(
        provider: 'apple',
        token: identityToken,
      );

      final authResponse = AuthResponse.fromJson(responseData);
      debugPrint('[AuthService] 백엔드 인증 완료: ${authResponse.user.email}');

      // 4. 토큰 저장
      await _saveTokens(authResponse);

      return authResponse;
    } catch (e, stackTrace) {
      debugPrint('[AuthService] Apple 로그인 실패: $e');
      debugPrint('[AuthService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Kakao 로그인 플로우
  ///
  /// 1. kakao_flutter_sdk로 Kakao 로그인 수행 (앱 우선)
  /// 2. Access Token 획득
  /// 3. 백엔드 API 호출하여 JWT 토큰 획득
  /// 4. 토큰 저장
  Future<AuthResponse> loginWithKakao() async {
    try {
      debugPrint('[AuthService] Kakao 로그인 시작');

      // 1. Kakao 로그인 수행 (카카오톡 앱 우선)
      kakao.OAuthToken token;

      // 카카오톡 설치 여부 확인
      final installed = await kakao.isKakaoTalkInstalled();
      debugPrint('[AuthService] 카카오톡 설치 여부: $installed');

      if (installed) {
        // 카카오톡 앱으로 로그인 시도
        try {
          debugPrint('[AuthService] 카카오톡 앱으로 로그인 시도');
          token = await kakao.UserApi.instance.loginWithKakaoTalk();
          debugPrint('[AuthService] 카카오톡 앱 로그인 성공');
        } catch (e) {
          // 사용자가 취소한 경우 예외 전파
          if (e.toString().contains('CANCELED') || e.toString().contains('User canceled')) {
            debugPrint('[AuthService] 사용자가 카카오 로그인을 취소함');
            throw Exception('LOGIN_CANCELED');
          }

          // 카카오톡 앱 로그인 실패 시 계정 로그인으로 전환
          debugPrint('[AuthService] 카카오톡 앱 로그인 실패, 계정 로그인으로 전환: $e');
          token = await kakao.UserApi.instance.loginWithKakaoAccount();
          debugPrint('[AuthService] Kakao 계정 로그인 성공');
        }
      } else {
        // 카카오톡 미설치 시 계정 로그인
        debugPrint('[AuthService] 카카오톡 미설치 - 계정 로그인 시도');
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
        debugPrint('[AuthService] Kakao 계정 로그인 성공');
      }

      // 2. Access Token 확인
      final accessToken = token.accessToken;
      if (accessToken.isEmpty) {
        throw Exception('Access Token을 가져올 수 없습니다.');
      }
      debugPrint('[AuthService] Kakao Access Token 획득 완료');

      // 3. 백엔드 API 호출
      final responseData = await _apiService.postSNSLogin(
        provider: 'kakao',
        token: accessToken,
      );

      final authResponse = AuthResponse.fromJson(responseData);
      debugPrint('[AuthService] 백엔드 인증 완료: ${authResponse.user.email}');

      // 4. 토큰 및 사용자 정보 저장
      await _saveTokens(authResponse);

      // Kakao 프로필 이미지 가져와서 저장
      try {
        final kakaoUser = await kakao.UserApi.instance.me();
        if (kakaoUser.kakaoAccount?.profile?.profileImageUrl != null) {
          final profileImageUrl = kakaoUser.kakaoAccount!.profile!.profileImageUrl!;
          await _storage.write(key: _profileImageKey, value: profileImageUrl);
          debugPrint('[AuthService] Kakao 프로필 이미지 저장: $profileImageUrl');
        }
      } catch (e) {
        debugPrint('[AuthService] Kakao 프로필 이미지 가져오기 실패: $e');
      }

      return authResponse;
    } catch (e, stackTrace) {
      debugPrint('[AuthService] Kakao 로그인 실패: $e');
      debugPrint('[AuthService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// 토큰 저장
  Future<void> _saveTokens(AuthResponse authResponse) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: authResponse.accessToken),
      _storage.write(key: _refreshTokenKey, value: authResponse.refreshToken),
      _storage.write(key: _userIdKey, value: authResponse.user.id.toString()),
      _storage.write(key: _userEmailKey, value: authResponse.user.email),
    ]);
    debugPrint('[AuthService] 토큰 저장 완료');
  }

  /// Access Token 가져오기
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Refresh Token 가져오기
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// 사용자 ID 가져오기
  Future<int?> getUserId() async {
    final userIdStr = await _storage.read(key: _userIdKey);
    if (userIdStr == null) return null;
    return int.tryParse(userIdStr);
  }

  /// 사용자 이메일 가져오기
  Future<String?> getUserEmail() async {
    return await _storage.read(key: _userEmailKey);
  }

  /// 사용자 이름 가져오기
  Future<String?> getUserName() async {
    return await _storage.read(key: _userNameKey);
  }

  /// 프로필 이미지 URL 가져오기
  Future<String?> getProfileImageUrl() async {
    return await _storage.read(key: _profileImageKey);
  }

  /// 로그인 상태 확인
  Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  /// 로그아웃
  Future<void> logout() async {
    try {
      // Firebase 로그아웃
      await FirebaseAuth.instance.signOut();
      
      // Google 로그아웃
      await _googleSignIn.signOut();

      // 저장된 토큰 및 사용자 정보 삭제
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _userIdKey),
        _storage.delete(key: _userEmailKey),
        _storage.delete(key: _userNameKey),
        _storage.delete(key: _profileImageKey),
      ]);

      debugPrint('[AuthService] 로그아웃 완료');
    } catch (e) {
      debugPrint('[AuthService] 로그아웃 중 오류: $e');
      rethrow;
    }
  }

  /// 이메일 인증코드 발송
  Future<EmailSendCodeResponse> sendEmailCode(String email) async {
    try {
      debugPrint('[AuthService] 이메일 인증코드 발송 요청: $email');

      final client = http.Client();
      final uri = Uri.parse(AppConfig.emailSendCodeUrl);
      final request = EmailSendCodeRequest(email: email);

      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        if (json['success'] == true) {
          debugPrint('[AuthService] 인증코드 발송 성공');
          return EmailSendCodeResponse(
            message: json['message'] ?? '인증코드가 발송되었습니다',
            expiresIn: 600, // 백엔드에서 10분 고정
          );
        }
        throw Exception(json['error'] ?? '인증코드 발송에 실패했습니다');
      }

      final json = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(json['error'] ?? '인증코드 발송에 실패했습니다');
    } catch (e) {
      debugPrint('[AuthService] 인증코드 발송 실패: $e');
      rethrow;
    }
  }

  /// 이메일 인증코드 확인
  Future<EmailVerifyCodeResponse> verifyEmailCode(String email, String code) async {
    try {
      debugPrint('[AuthService] 이메일 인증코드 확인 요청');

      final client = http.Client();
      final uri = Uri.parse(AppConfig.emailVerifyCodeUrl);
      final request = EmailVerifyCodeRequest(email: email, code: code);

      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint('[AuthService] 인증코드 확인 성공');
        return EmailVerifyCodeResponse.fromJson(json);
      }

      final json = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(json['error'] ?? '인증코드가 올바르지 않습니다');
    } catch (e) {
      debugPrint('[AuthService] 인증코드 확인 실패: $e');
      rethrow;
    }
  }

  /// 이메일 로그인
  Future<AuthResponse> loginWithEmail(String email, String password) async {
    try {
      debugPrint('[AuthService] 이메일 로그인 시작: $email');

      final client = http.Client();
      final uri = Uri.parse(AppConfig.loginUrl);
      final request = LoginRequest(email: email, password: password);

      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        if (json['success'] == true && json['data'] != null) {
          final authResponse = AuthResponse.fromJson(json['data']);
          await _saveTokens(authResponse);
          debugPrint('[AuthService] 이메일 로그인 성공');
          return authResponse;
        }
        throw Exception(json['error'] ?? '로그인에 실패했습니다');
      }

      final json = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(json['error'] ?? '로그인에 실패했습니다');
    } catch (e) {
      debugPrint('[AuthService] 이메일 로그인 실패: $e');
      rethrow;
    }
  }

  /// 회원가입
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    required String verificationToken,
  }) async {
    try {
      debugPrint('[AuthService] 회원가입 시작: $email');

      final client = http.Client();
      final uri = Uri.parse(AppConfig.signupUrl);
      final request = SignUpRequest(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        verificationToken: verificationToken,
      );

      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        if (json['success'] == true && json['data'] != null) {
          final authResponse = AuthResponse.fromJson(json['data']);
          await _saveTokens(authResponse);
          debugPrint('[AuthService] 회원가입 성공');
          return authResponse;
        }
        throw Exception(json['error'] ?? '회원가입에 실패했습니다');
      }

      final json = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(json['error'] ?? '회원가입에 실패했습니다');
    } catch (e) {
      debugPrint('[AuthService] 회원가입 실패: $e');
      rethrow;
    }
  }

  /// Refresh Token으로 새 토큰 발급
  Future<AuthResponse> refreshToken() async {
    try {
      debugPrint('[AuthService] 토큰 갱신 시작');

      final refreshTokenValue = await getRefreshToken();
      if (refreshTokenValue == null) {
        throw Exception('Refresh Token이 없습니다');
      }

      final client = http.Client();
      final uri = Uri.parse(AppConfig.refreshTokenUrl);
      final request = RefreshTokenRequest(refreshToken: refreshTokenValue);

      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        if (json['success'] == true && json['data'] != null) {
          final authResponse = AuthResponse.fromJson(json['data']);
          await _saveTokens(authResponse);
          debugPrint('[AuthService] 토큰 갱신 성공');
          return authResponse;
        }
        throw Exception(json['error'] ?? '토큰 갱신에 실패했습니다');
      }

      final json = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(json['error'] ?? '토큰 갱신에 실패했습니다');
    } catch (e) {
      debugPrint('[AuthService] 토큰 갱신 실패: $e');
      rethrow;
    }
  }

  /// 비밀번호 재설정 요청
  Future<void> passwordResetRequest(String email) async {
    try {
      debugPrint('[AuthService] 비밀번호 재설정 요청: $email');

      final client = http.Client();
      final uri = Uri.parse(AppConfig.passwordResetRequestUrl);
      final request = PasswordResetRequest(email: email);

      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        debugPrint('[AuthService] 비밀번호 재설정 요청 성공');
        return;
      }

      // 보안상 이유로 실패해도 성공 메시지 반환
      debugPrint('[AuthService] 비밀번호 재설정 요청 처리 완료');
    } catch (e) {
      debugPrint('[AuthService] 비밀번호 재설정 요청 실패: $e');
      // 보안상 이유로 에러를 던지지 않음
    }
  }

  /// 비밀번호 재설정 인증코드 확인
  Future<PasswordResetVerifyResponse> passwordResetVerify(String email, String code) async {
    try {
      debugPrint('[AuthService] 비밀번호 재설정 인증코드 확인');

      final client = http.Client();
      final uri = Uri.parse(AppConfig.passwordResetVerifyUrl);
      final request = PasswordResetVerifyRequest(email: email, code: code);

      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint('[AuthService] 비밀번호 재설정 인증코드 확인 성공');
        // 백엔드 응답에 verified 필드가 없을 수 있으므로 reset_token 존재 여부로 판단
        final resetToken = json['reset_token'] as String? ?? '';
        return PasswordResetVerifyResponse(
          verified: resetToken.isNotEmpty,
          resetToken: resetToken,
          expiresIn: 3600, // 백엔드에서 60분 고정
        );
      }

      final json = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(json['error'] ?? '인증코드가 올바르지 않습니다');
    } catch (e) {
      debugPrint('[AuthService] 비밀번호 재설정 인증코드 확인 실패: $e');
      rethrow;
    }
  }

  /// 비밀번호 재설정 확정
  Future<void> passwordResetConfirm(String email, String resetToken, String newPassword) async {
    try {
      debugPrint('[AuthService] 비밀번호 재설정 확정');

      final client = http.Client();
      final uri = Uri.parse(AppConfig.passwordResetConfirmUrl);
      final request = PasswordResetConfirmRequest(
        email: email,
        resetToken: resetToken,
        newPassword: newPassword,
      );

      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('[AuthService] 비밀번호 재설정 성공');
        return;
      }

      final json = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(json['error'] ?? '비밀번호 변경에 실패했습니다');
    } catch (e) {
      debugPrint('[AuthService] 비밀번호 재설정 실패: $e');
      rethrow;
    }
  }

  /// 현재 사용자 정보 조회
  Future<Map<String, dynamic>> getUserInfo() async {
    try {
      debugPrint('[AuthService] 사용자 정보 조회');

      final accessToken = await getAccessToken();
      if (accessToken == null) {
        throw Exception('로그인이 필요합니다');
      }

      final client = http.Client();
      final uri = Uri.parse(AppConfig.meUrl);

      final response = await client
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        if (json['success'] == true && json['data'] != null) {
          debugPrint('[AuthService] 사용자 정보 조회 성공');
          return json['data'] as Map<String, dynamic>;
        }
        throw Exception(json['error'] ?? '사용자 정보를 가져올 수 없습니다');
      }

      final json = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(json['error'] ?? '사용자 정보를 가져올 수 없습니다');
    } catch (e) {
      debugPrint('[AuthService] 사용자 정보 조회 실패: $e');
      rethrow;
    }
  }

  /// 회원 탈퇴
  Future<void> deleteAccount({String? reason}) async {
    try {
      debugPrint('[AuthService] 회원 탈퇴 요청${reason != null ? " (사유: $reason)" : ""}');

      final accessToken = await getAccessToken();
      if (accessToken == null) {
        throw Exception('로그인이 필요합니다');
      }

      final client = http.Client();
      final uri = Uri.parse(AppConfig.meUrl);

      // 탈퇴 사유를 body에 포함
      final requestBody = reason != null ? jsonEncode({'reason': reason}) : null;

      final response = await client
          .delete(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // 탈퇴 성공 시 로그아웃 처리
        await logout();
        debugPrint('[AuthService] 회원 탈퇴 성공');
        return;
      }

      final json = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(json['error'] ?? '회원 탈퇴에 실패했습니다');
    } catch (e) {
      debugPrint('[AuthService] 회원 탈퇴 실패: $e');
      rethrow;
    }
  }
}
