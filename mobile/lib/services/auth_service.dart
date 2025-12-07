import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/auth_response.dart';
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

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';

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
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google 로그인이 취소되었습니다.');
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

      // 6. 토큰 저장
      await _saveTokens(authResponse);

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

      final clientId = dotenv.env['APPLE_CLIENT_ID'] ?? 'com.woohalabs.ojeomneo';

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
  /// 1. kakao_flutter_sdk로 Kakao 로그인 수행
  /// 2. Access Token 획득
  /// 3. 백엔드 API 호출하여 JWT 토큰 획득
  /// 4. 토큰 저장
  Future<AuthResponse> loginWithKakao() async {
    try {
      debugPrint('[AuthService] Kakao 로그인 시작');

      // Kakao SDK 초기화 확인 (main.dart에서 수행)
      final nativeAppKey = dotenv.env['KAKAO_NATIVE_APP_KEY'];
      if (nativeAppKey == null) {
        throw Exception('KAKAO_NATIVE_APP_KEY가 설정되지 않았습니다.');
      }

      // 1. Kakao 로그인 수행
      OAuthToken token;
      try {
        token = await kakao.UserApi.instance.loginWithKakaoTalk();
        debugPrint('[AuthService] KakaoTalk 로그인 성공');
      } catch (e) {
        // KakaoTalk 앱이 설치되지 않았거나 로그인 실패 시 카카오계정으로 로그인 시도
        try {
          token = await kakao.UserApi.instance.loginWithKakaoAccount();
          debugPrint('[AuthService] Kakao 계정 로그인 성공');
        } catch (e2) {
          debugPrint('[AuthService] Kakao 로그인 실패: $e2');
          throw Exception('Kakao 로그인에 실패했습니다.');
        }
      }

      // 2. Access Token 확인
      if (token.accessToken == null) {
        throw Exception('Access Token을 가져올 수 없습니다.');
      }

      final accessToken = token.accessToken!;
      debugPrint('[AuthService] Kakao Access Token 획득 완료');

      // 3. 백엔드 API 호출
      final responseData = await _apiService.postSNSLogin(
        provider: 'kakao',
        token: accessToken,
      );

      final authResponse = AuthResponse.fromJson(responseData);
      debugPrint('[AuthService] 백엔드 인증 완료: ${authResponse.user.email}');

      // 4. 토큰 저장
      await _saveTokens(authResponse);

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
      await GoogleSignIn().signOut();

      // 저장된 토큰 삭제
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _userIdKey),
        _storage.delete(key: _userEmailKey),
      ]);

      debugPrint('[AuthService] 로그아웃 완료');
    } catch (e) {
      debugPrint('[AuthService] 로그아웃 중 오류: $e');
      rethrow;
    }
  }
}

