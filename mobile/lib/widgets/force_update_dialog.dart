import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_version.dart';

/// 강제 업데이트 다이얼로그
class ForceUpdateDialog extends StatelessWidget {
  final AppVersionResponse versionInfo;

  const ForceUpdateDialog({
    super.key,
    required this.versionInfo,
  });

  /// 강제 업데이트 다이얼로그 표시
  static Future<void> show(BuildContext context, AppVersionResponse versionInfo) {
    return showDialog(
      context: context,
      barrierDismissible: false, // 닫기 불가
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.5), // 회색 반투명 오버레이
      builder: (context) => ForceUpdateDialog(versionInfo: versionInfo),
    );
  }

  Future<void> _openStore() async {
    final url = Uri.parse(versionInfo.storeUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 뒤로가기 버튼 비활성화
      child: Dialog(
        backgroundColor: Colors.white, // 흰색 배경
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.system_update,
                  size: 32,
                  color: Colors.blue.shade600,
                ),
              ),
              const SizedBox(height: 20),

              // 제목
              const Text(
                '업데이트 안내',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // 메시지
              Text(
                versionInfo.updateMessage.isNotEmpty
                    ? versionInfo.updateMessage
                    : '더 나은 서비스를 위해 최신 버전으로 업데이트해 주세요.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),

              // 버전 정보
              Text(
                '최신 버전: ${versionInfo.latestVersion}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // 업데이트 버튼
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _openStore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '업데이트 하러가기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
