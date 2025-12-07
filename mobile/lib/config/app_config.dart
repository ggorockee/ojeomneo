import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = '오점너';
  static const String appVersion = '1.0.0';

  // API 설정 - 서버에서 동적으로 가져올 수 있도록 구성
  static const String baseUrl = 'https://api.woohalabs.com';
  static const String apiVersion = 'v1';
  static const String apiPrefix = '/ojeomneo/$apiVersion';

  // 개발/운영 환경 자동 감지
  static bool get isDevelopment => kDebugMode;

  static String get apiUrl => '$baseUrl$apiPrefix';

  // API Endpoints
  static String get sketchAnalyzeUrl => '$apiUrl/sketch/analyze';
  static String get sketchHistoryUrl => '$apiUrl/sketch/history';
  static String get menusUrl => '$apiUrl/menus';
  static String get menuCategoriesUrl => '$apiUrl/menus/categories';

  // Auth Endpoints
  static String get googleLoginUrl => '$apiUrl/auth/google';
  static String get appleLoginUrl => '$apiUrl/auth/apple';
  static String get kakaoLoginUrl => '$apiUrl/auth/kakao';
  static String get emailSendCodeUrl => '$apiUrl/auth/email/send-code';
  static String get emailVerifyCodeUrl => '$apiUrl/auth/email/verify-code';
  static String get signupUrl => '$apiUrl/auth/signup';
  static String get loginUrl => '$apiUrl/auth/login';
  static String get refreshTokenUrl => '$apiUrl/auth/refresh';
  static String get passwordResetRequestUrl => '$apiUrl/auth/password/reset-request';
  static String get passwordResetVerifyUrl => '$apiUrl/auth/password/reset-verify';
  static String get passwordResetConfirmUrl => '$apiUrl/auth/password/reset-confirm';
  static String get meUrl => '$apiUrl/auth/me';

  // 이미지 설정
  static const int maxImageSize = 512;
  static const int imageQuality = 85;

  // Rate Limiting
  static const int dailyRecommendationLimit = 10;
}
