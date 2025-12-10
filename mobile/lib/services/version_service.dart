import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/app_version.dart';

/// 앱 버전 체크 서비스
class VersionService {
  /// 서버에서 버전 정보를 가져오고 강제 업데이트 필요 여부를 확인
  static Future<AppVersionResponse?> checkVersion() async {
    try {
      // 현재 앱 버전 - AppConfig에서 가져오기
      final currentVersion = AppConfig.appVersion;

      // 플랫폼 확인
      final platform = Platform.isIOS ? 'ios' : 'android';

      // API 호출
      final uri = Uri.parse(
        '${AppConfig.apiUrl}/app/version?platform=$platform&current_version=$currentVersion',
      );

      print('[VersionService] Checking version: $uri');
      print('[VersionService] Current version: $currentVersion, Platform: $platform');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      print('[VersionService] Response status: ${response.statusCode}');
      print('[VersionService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          final versionResponse = AppVersionResponse.fromJson(json['data']);
          print('[VersionService] Version check result: needsUpdate=${versionResponse.needsUpdate}, forceUpdate=${versionResponse.forceUpdate}');
          return versionResponse;
        }
      }

      print('[VersionService] No version info available or invalid response');
      return null;
    } catch (e, stackTrace) {
      // 네트워크 오류 등의 경우 null 반환 (앱 사용 허용)
      print('[VersionService] Error checking version: $e');
      print('[VersionService] Stack trace: $stackTrace');
      return null;
    }
  }
}
