import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

/// ProfileScreen
/// ------------------------------------------------------
/// 사용자 프로필 및 설정 화면
/// - 사용자 정보 표시
/// - 앱 설정
/// - 회원탈퇴
/// - 로그아웃
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  bool _isLoading = false;

  /// 로그아웃 처리
  Future<void> _handleLogout() async {
    final confirmed = await _showConfirmDialog(
      title: '로그아웃',
      message: '정말 로그아웃하시겠습니까?',
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _authService.logout();

      if (mounted) {
        // 로그인 화면으로 이동
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage('로그아웃에 실패했습니다: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 회원탈퇴 처리
  Future<void> _handleDeleteAccount() async {
    // 1차 확인
    final confirmed = await _showConfirmDialog(
      title: '회원탈퇴',
      message: '정말 탈퇴하시겠습니까?\n모든 데이터가 삭제되며 복구할 수 없습니다.',
      confirmText: '탈퇴',
      isDangerous: true,
    );

    if (confirmed != true) return;

    // 탈퇴 사유 선택
    final reason = await _showDeleteReasonDialog();
    if (reason == null) return;

    // 2차 최종 확인
    final finalConfirmed = await _showConfirmDialog(
      title: '최종 확인',
      message: '정말로 탈퇴하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
      confirmText: '탈퇴',
      isDangerous: true,
    );

    if (finalConfirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _authService.deleteAccount(reason: reason);

      if (mounted) {
        _showMessage('회원탈퇴가 완료되었습니다.');

        // 로그인 화면으로 이동
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage('회원탈퇴에 실패했습니다: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 탈퇴 사유 선택 다이얼로그
  Future<String?> _showDeleteReasonDialog() async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => _DeleteReasonBottomSheet(),
    );
  }

  /// 확인 다이얼로그
  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    String confirmText = '확인',
    bool isDangerous = false,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6C7278),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '취소',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6C7278),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmText,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isDangerous ? Colors.red : AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// URL 열기
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        _showMessage('링크를 열 수 없습니다.');
      }
    }
  }

  /// 메시지 표시
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          '내정보',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1C1E),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 24.h),

                  // 사용자 정보 섹션
                  _buildUserInfoSection(),

                  SizedBox(height: 24.h),

                  // 설정 섹션
                  _buildSettingsSection(),

                  SizedBox(height: 24.h),

                  // 정보 섹션
                  _buildInfoSection(),

                  SizedBox(height: 24.h),

                  // 계정 관리 섹션
                  _buildAccountSection(),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
    );
  }

  /// 사용자 정보 섹션
  Widget _buildUserInfoSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 프로필 아이콘
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 32.sp,
              color: Colors.white,
            ),
          ),

          SizedBox(width: 16.w),

          // 사용자 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '사용자님',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'user@example.com',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6C7278),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 설정 섹션
  Widget _buildSettingsSection() {
    return _buildSection(
      title: '설정',
      children: [
        _buildMenuItem(
          icon: Icons.notifications_outlined,
          title: '알림 설정',
          onTap: () {
            _showMessage('알림 설정은 준비 중입니다.');
          },
        ),
        _buildDivider(),
        _buildMenuItem(
          icon: Icons.language_outlined,
          title: '언어 설정',
          onTap: () {
            _showMessage('언어 설정은 준비 중입니다.');
          },
        ),
      ],
    );
  }

  /// 정보 섹션
  Widget _buildInfoSection() {
    return _buildSection(
      title: '정보',
      children: [
        _buildMenuItem(
          icon: Icons.description_outlined,
          title: '서비스 이용약관',
          onTap: () => _openUrl('https://ojeomneo.com/terms'),
        ),
        _buildDivider(),
        _buildMenuItem(
          icon: Icons.privacy_tip_outlined,
          title: '개인정보 처리방침',
          onTap: () => _openUrl('https://ojeomneo.com/privacy'),
        ),
        _buildDivider(),
        _buildMenuItem(
          icon: Icons.info_outline,
          title: '앱 정보',
          trailing: Text(
            'v1.0.0',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6C7278),
            ),
          ),
          onTap: () {
            _showMessage('오점너 v1.0.0');
          },
        ),
      ],
    );
  }

  /// 계정 관리 섹션
  Widget _buildAccountSection() {
    return _buildSection(
      title: '계정',
      children: [
        _buildMenuItem(
          icon: Icons.logout_outlined,
          title: '로그아웃',
          titleColor: AppTheme.primaryColor,
          onTap: _handleLogout,
        ),
        _buildDivider(),
        _buildMenuItem(
          icon: Icons.delete_outline,
          title: '회원탈퇴',
          titleColor: Colors.red,
          onTap: _handleDeleteAccount,
        ),
      ],
    );
  }

  /// 섹션 컨테이너
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6C7278),
              letterSpacing: -0.13,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  /// 메뉴 아이템
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24.sp,
              color: titleColor ?? const Color(0xFF1A1C1E),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: titleColor ?? const Color(0xFF1A1C1E),
                  letterSpacing: -0.15,
                ),
              ),
            ),
            if (trailing != null) trailing
            else
              Icon(
                Icons.chevron_right,
                size: 20.sp,
                color: const Color(0xFF6C7278),
              ),
          ],
        ),
      ),
    );
  }

  /// 구분선
  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Divider(
        height: 1,
        thickness: 1,
        color: const Color(0xFFEDF1F3),
      ),
    );
  }
}

/// 탈퇴 사유 선택 바텀시트
class _DeleteReasonBottomSheet extends StatefulWidget {
  @override
  State<_DeleteReasonBottomSheet> createState() => _DeleteReasonBottomSheetState();
}

class _DeleteReasonBottomSheetState extends State<_DeleteReasonBottomSheet> {
  String? _selectedReason;

  final List<String> _reasons = [
    '더 이상 사용하지 않아요',
    '원하는 메뉴가 없어요',
    '추천 결과가 마음에 들지 않아요',
    '앱이 불편하고 오류가 많아요',
    '개인정보가 걱정돼요',
    '기타',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '탈퇴 사유를 선택해 주세요',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1C1E),
            ),
          ),

          SizedBox(height: 20.h),

          ..._reasons.map((reason) => _buildReasonTile(reason)),

          SizedBox(height: 20.h),

          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed: _selectedReason == null
                  ? null
                  : () => Navigator.of(context).pop(_selectedReason),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                disabledBackgroundColor: const Color(0xFFEDF1F3),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: Text(
                '다음',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonTile(String reason) {
    final isSelected = _selectedReason == reason;

    return InkWell(
      onTap: () => setState(() => _selectedReason = reason),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFEDF1F3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 20.sp,
              color: isSelected ? AppTheme.primaryColor : const Color(0xFF6C7278),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                reason,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppTheme.primaryColor : const Color(0xFF1A1C1E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
