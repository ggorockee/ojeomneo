/// 앱 버전 응답 모델
class AppVersionResponse {
  final bool forceUpdate;
  final String latestVersion;
  final String minVersion;
  final String storeUrl;
  final String updateMessage;

  AppVersionResponse({
    required this.forceUpdate,
    required this.latestVersion,
    required this.minVersion,
    required this.storeUrl,
    required this.updateMessage,
  });

  factory AppVersionResponse.fromJson(Map<String, dynamic> json) {
    return AppVersionResponse(
      forceUpdate: json['force_update'] ?? false,
      latestVersion: json['latest_version'] ?? '',
      minVersion: json['min_version'] ?? '',
      storeUrl: json['store_url'] ?? '',
      updateMessage: json['update_message'] ?? '',
    );
  }
}
