import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_config.dart';
import '../models/app_version.dart';

/// 앱 버전 체크 서비스
class VersionService {
  /// 서버에서 버전 정보를 가져오고 강제 업데이트 필요 여부를 확인
  static Future<AppVersionResponse?> checkVersion() async {
    try {
      // 현재 앱 버전 가져오기
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // 플랫폼 확인
      final platform = Platform.isIOS ? 'ios' : 'android';

      // API 호출
      final uri = Uri.parse(
        '${AppConfig.baseUrl}/app/version?platform=$platform&current_version=$currentVersion',
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return AppVersionResponse.fromJson(json['data']);
        }
      }

      return null;
    } catch (e) {
      // 네트워크 오류 등의 경우 null 반환 (앱 사용 허용)
      return null;
    }
  }
}
