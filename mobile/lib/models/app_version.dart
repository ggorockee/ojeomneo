/// 앱 버전 응답 모델
class AppVersionResponse {
  final bool needsUpdate; // 업데이트 필요 여부
  final bool forceUpdate; // 강제 업데이트 여부
  final String latestVersion; // 최신 버전
  final String minVersion; // 최소 지원 버전
  final String storeUrl; // 앱 스토어 URL
  final String updateMessage; // 업데이트 메시지

  AppVersionResponse({
    required this.needsUpdate,
    required this.forceUpdate,
    required this.latestVersion,
    required this.minVersion,
    required this.storeUrl,
    required this.updateMessage,
  });

  factory AppVersionResponse.fromJson(Map<String, dynamic> json) {
    return AppVersionResponse(
      needsUpdate: json['needs_update'] ?? false,
      forceUpdate: json['force_update'] ?? false,
      latestVersion: json['latest_version'] ?? '',
      minVersion: json['min_version'] ?? '',
      storeUrl: json['store_url'] ?? '',
      updateMessage: json['update_message'] ?? '',
    );
  }
}

