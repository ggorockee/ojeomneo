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

  // 이미지 설정
  static const int maxImageSize = 512;
  static const int imageQuality = 85;

  // Rate Limiting
  static const int dailyRecommendationLimit = 10;
}
