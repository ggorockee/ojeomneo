import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_theme.dart';
import '../services/auth_service.dart';
import 'auth/password_reset_screen.dart';
import 'auth/sign_up_screen.dart';

/// 로그인 화면
/// 참고 앱의 로그인 화면을 기반으로 제작
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 로그인 없이 진행
  void _handleContinueWithoutLogin() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  /// 카카오 로그인 처리
  Future<void> _handleKakaoLogin() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.loginWithKakao();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('카카오 로그인에 실패했습니다: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 구글 로그인 처리
  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.loginWithGoogle();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('구글 로그인에 실패했습니다: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 애플 로그인 처리
  Future<void> _handleAppleLogin() async {
    if (_isLoading) return;
    
    if (!Platform.isIOS) {
      _showMessage('Apple 로그인은 iOS에서만 사용할 수 있습니다.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.loginWithApple();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Apple 로그인에 실패했습니다: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 이메일 로그인 처리 (임시)
  Future<void> _handleEmailLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      _showMessage('이메일을 입력해 주세요.');
      return;
    }

    if (password.isEmpty) {
      _showMessage('비밀번호를 입력해 주세요.');
      return;
    }

    // TODO: 이메일 로그인 구현 (백엔드 API 연동 필요)
    _showMessage('이메일 로그인은 준비 중입니다.');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 32.h),

                      // 헤드라인
                      _buildHeadline(),

                      SizedBox(height: 24.h),
                      
                      // 이메일 입력 필드
                      _buildInputField(
                        title: '이메일',
                        controller: _emailController,
                        hintText: '이메일을 입력해 주세요',
                        prefixIcon: Icons.person_outline,
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // 비밀번호 입력 필드
                      _buildPasswordField(),

                      SizedBox(height: 8.h),

                      // 비밀번호 찾기 (비밀번호 필드 바로 아래)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: 비밀번호 찾기 화면 구현 (ForgotPasswordScreen)
                            _showMessage('비밀번호 찾기는 준비 중입니다.');
                          },
                          child: Text(
                            '비밀번호를 잊으셨나요?',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                              letterSpacing: -0.12,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16.h),
                      
                      // 로그인 버튼
                      _buildLoginButton(),

                      SizedBox(height: 12.h),

                      // 비밀번호 찾기 링크
                      _buildForgotPasswordLink(),

                      SizedBox(height: 20.h),

                      // 또는 구분선
                      _buildOrDivider(),

                      SizedBox(height: 20.h),

                      // 소셜 로그인 버튼들
                      _buildSocialLoginButtons(),

                      // 로그인 없이 진행 버튼 (카카오 로그인 아래)
                      SizedBox(height: 12.h),
                      _buildContinueWithoutLoginButton(),

                      SizedBox(height: 24.h),

                      // 회원가입 링크
                      _buildSignUpLink(),

                      SizedBox(height: 24.h),

                      // 개인정보 처리방침 및 이용약관
                      _buildPolicyLinks(),

                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 헤드라인 섹션
  Widget _buildHeadline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '로그인',
          style: TextStyle(
            fontSize: 32.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1C1E),
            letterSpacing: -0.64,
            height: 1.3,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          '이메일과 비밀번호를 입력해 주세요',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6C7278),
            letterSpacing: -0.12,
          ),
        ),
      ],
    );
  }

  // 일반 입력 필드
  Widget _buildInputField({
    required String title,
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6C7278),
            letterSpacing: -0.24,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          height: 46.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: const Color(0xFFEDF1F3),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1C1E),
              letterSpacing: -0.14,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6C7278),
              ),
              prefixIcon: Icon(
                prefixIcon,
                size: 16.sp,
                color: const Color(0xFF6C7278),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 13.h,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 비밀번호 입력 필드
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '비밀번호',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6C7278),
            letterSpacing: -0.24,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          height: 46.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: const Color(0xFFEDF1F3),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1C1E),
              letterSpacing: -0.14,
            ),
            decoration: InputDecoration(
              hintText: '비밀번호를 입력해 주세요',
              hintStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6C7278),
              ),
              prefixIcon: Icon(
                Icons.lock_outline,
                size: 16.sp,
                color: const Color(0xFF6C7278),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword 
                    ? Icons.visibility_off_outlined 
                    : Icons.visibility_outlined,
                  size: 16.sp,
                  color: const Color(0xFF6C7278),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 13.h,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 로그인 버튼
  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 48.h,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleEmailLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          padding: EdgeInsets.zero,
        ),
        child: _isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                '로그인',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.14,
                ),
              ),
      ),
    );
  }

  // 또는 구분선
  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFEDF1F3),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            '또는',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6C7278),
              letterSpacing: -0.12,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFEDF1F3),
          ),
        ),
      ],
    );
  }

  // 소셜 로그인 버튼들
  Widget _buildSocialLoginButtons() {
    return Column(
      children: [
        // Google
        _buildSocialButton(
          text: 'Google로 시작하기',
          logoPath: 'assets/images/login/google.png',
          logoLeftPadding: 0,
          onPressed: _isLoading ? null : _handleGoogleLogin,
        ),
        SizedBox(height: 12.h),

        // Apple (iOS에서만 표시)
        if (Platform.isIOS) ...[
          _buildSocialButton(
            text: 'Apple로 시작하기',
            logoPath: 'assets/images/login/apple.png',
            logoLeftPadding: -2,
            onPressed: _isLoading ? null : _handleAppleLogin,
          ),
          SizedBox(height: 12.h),
        ],

        // Kakao
        _buildSocialButton(
          text: 'Kakao로 시작하기',
          logoPath: 'assets/images/login/kakao.png',
          logoLeftPadding: -1,
          onPressed: _isLoading ? null : _handleKakaoLogin,
        ),
      ],
    );
  }

  // 소셜 로그인 버튼 공통
  Widget _buildSocialButton({
    required String text,
    String? logoPath,
    double logoLeftPadding = 0,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 48.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: const Color(0xFFEFF0F6),
          width: 1,
        ),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 이미지 (있는 경우만)
            if (logoPath != null) ...[
              Transform.translate(
                offset: Offset(logoLeftPadding, 0),
                child: Image.asset(
                  logoPath,
                  width: 20.w,
                  height: 20.w,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: 12.w),
            ],
            // 버튼 텍스트
            Text(
              text,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1C1E),
                letterSpacing: -0.14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 로그인 없이 진행 버튼
  Widget _buildContinueWithoutLoginButton() {
    return Container(
      width: double.infinity,
      height: 48.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: const Color(0xFFEDF1F3),
          width: 1,
        ),
      ),
      child: TextButton(
        onPressed: _isLoading ? null : _handleContinueWithoutLogin,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          '로그인 없이 진행',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
            letterSpacing: -0.14,
          ),
        ),
      ),
    );
  }

  // 비밀번호 찾기 링크
  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PasswordResetScreen(),
            ),
          );
        },
        child: Text(
          '비밀번호 찾기',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6C7278),
            letterSpacing: -0.12,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  // 회원가입 링크
  Widget _buildSignUpLink() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '계정이 없으신가요?',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6C7278),
              letterSpacing: -0.12,
            ),
          ),
          SizedBox(width: 4.w),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SignUpScreen(),
                ),
              );
            },
            child: Text(
              '회원가입',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
                letterSpacing: -0.12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 개인정보 처리방침 및 이용약관 링크
  Widget _buildPolicyLinks() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _openUrl('https://ojeomneo.com/privacy'),
            child: Text(
              '개인정보 처리방침',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6C7278),
                letterSpacing: -0.11,
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFF6C7278),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              '|',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFEDF1F3),
                letterSpacing: -0.11,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _openUrl('https://ojeomneo.com/terms'),
            child: Text(
              '서비스 이용약관',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6C7278),
                letterSpacing: -0.11,
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFF6C7278),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

