/// 앱 설정
class AppConfig {
  /// API 기본 URL
  static const String apiBaseUrl = 'https://api.woohalabs.com/ojeomneo/v1';

  /// 개발 환경 API URL
  static const String devApiBaseUrl = 'http://localhost:3000/ojeomneo/v1';

  /// 현재 환경이 개발 환경인지 여부
  static const bool isDevelopment = true;

  /// 사용할 API URL
  static String get baseUrl => isDevelopment ? devApiBaseUrl : apiBaseUrl;
}
