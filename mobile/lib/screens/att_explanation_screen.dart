import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

import '../services/auth_service.dart';

/// ATT (App Tracking Transparency) 권한 설명 화면
///
/// iOS 14.5+ 사용자에게 광고 추적 권한이 필요한 이유를 설명하고
/// 사용자의 동의를 구하는 화면입니다.
class ATTExplanationScreen extends StatelessWidget {
  const ATTExplanationScreen({super.key});

  /// ATT 권한 요청 및 다음 화면 이동
  Future<void> _requestPermissionAndNavigate(BuildContext context) async {
    if (Platform.isIOS) {
      try {
        // ATT 권한 요청 (시스템 다이얼로그 표시)
        await AppTrackingTransparency.requestTrackingAuthorization();
      } catch (e) {
        debugPrint('ATT 권한 요청 실패: $e');
      }
    }

    // 권한 요청 결과와 관계없이 다음 화면으로 이동
    if (context.mounted) {
      _navigateToNextScreen(context);
    }
  }

  /// 권한 요청 없이 다음 화면 이동
  void _skipAndNavigate(BuildContext context) {
    _navigateToNextScreen(context);
  }

  /// 다음 화면으로 이동 (로그인 상태에 따라 로그인 또는 홈)
  Future<void> _navigateToNextScreen(BuildContext context) async {
    // 로그인 상태 확인
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();

    if (!context.mounted) return;

    // 로그인 되어 있으면 홈, 아니면 로그인 화면으로 이동
    if (isLoggedIn) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 60.h),

              // 아이콘
              Icon(
                Icons.privacy_tip_outlined,
                size: 80.sp,
                color: const Color(0xFFFF6B35),
              ),

              SizedBox(height: 32.h),

              // 제목
              Text(
                '더 나은 서비스를 위한\n맞춤 광고 안내',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),

              SizedBox(height: 24.h),

              // 설명
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBulletPoint(
                      '오점너는 무료 광고 기반 서비스입니다',
                      '앱을 무료로 이용하실 수 있도록 광고를 통해 운영됩니다',
                    ),
                    SizedBox(height: 16.h),
                    _buildBulletPoint(
                      '맞춤 광고로 더 나은 경험을',
                      '관심사에 맞는 광고를 보여드려 불필요한 광고를 줄입니다',
                    ),
                    SizedBox(height: 16.h),
                    _buildBulletPoint(
                      '개인정보는 안전하게 보호됩니다',
                      '광고 식별자만 사용되며, 개인 정보는 수집하지 않습니다',
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // 안내 문구
              Text(
                '추적 허용은 언제든지 iOS 설정에서 변경하실 수 있습니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),

              const Spacer(),

              // 동의 버튼
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: () => _requestPermissionAndNavigate(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    '동의하고 시작하기',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12.h),

              // 나중에 버튼
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: TextButton(
                  onPressed: () => _skipAndNavigate(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    '나중에',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  /// Bullet point 스타일의 설명 위젯
  Widget _buildBulletPoint(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 4.h),
          width: 6.w,
          height: 6.w,
          decoration: const BoxDecoration(
            color: Color(0xFFFF6B35),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
