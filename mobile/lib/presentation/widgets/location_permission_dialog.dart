import 'package:flutter/material.dart';

/// 위치 권한 요청 다이얼로그
class LocationPermissionDialog extends StatelessWidget {
  final bool isPermanentlyDenied;
  final VoidCallback onDeny;
  final VoidCallback onAllow;

  const LocationPermissionDialog({
    super.key,
    required this.isPermanentlyDenied,
    required this.onDeny,
    required this.onAllow,
  });

  /// 다이얼로그 표시
  static Future<void> show(
    BuildContext context, {
    required bool isPermanentlyDenied,
    required VoidCallback onDeny,
    required VoidCallback onAllow,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // 외부 터치로 닫기 방지
      builder: (context) => LocationPermissionDialog(
        isPermanentlyDenied: isPermanentlyDenied,
        onDeny: onDeny,
        onAllow: onAllow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘
            Icon(
              Icons.location_on,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),

            // 메인 메시지
            Text(
              isPermanentlyDenied
                  ? '설정에서 위치 권한을\n허용해주세요'
                  : '위치 권한을\n허용해주세요',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),

            // 영구 거부 시 추가 안내
            if (isPermanentlyDenied) ...[
              const SizedBox(height: 8),
              Text(
                '앱 설정 > 권한 > 위치',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],

            // 권한이 필요한 이유 설명
            if (!isPermanentlyDenied) ...[
              const SizedBox(height: 12),
              Text(
                '주변 맛집 정보를 표시하기 위해\n위치 권한이 필요합니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        // 거절 버튼
        TextButton(
          onPressed: onDeny,
          child: Text(
            '거절',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),

        // 허용/설정 열기 버튼
        ElevatedButton(
          onPressed: onAllow,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
          child: Text(
            isPermanentlyDenied ? '설정 열기' : '허용',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
    );
  }
}
