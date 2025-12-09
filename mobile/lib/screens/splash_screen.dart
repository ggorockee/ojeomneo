import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../config/app_theme.dart';
import '../config/app_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 페이드 인 애니메이션
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    // 로고 크기 애니메이션 (커졌다 작아졌다) - 더 큰 변화
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.3).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // 스케일 반복
    _scaleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _scaleController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _scaleController.forward();
      }
    });

    // 애니메이션 시작
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _scaleController.forward();
    });

    // 화면 전환 (스플래시 후 로그인 화면으로 이동)
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([_fadeController, _scaleController]),
        builder: (context, child) {
          return Stack(
            children: [
              // 중앙 컨텐츠
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 로고 with 크기 애니메이션
                      Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: 160.w,
                          height: 160.w,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 160.w,
                              height: 160.w,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 28.h),
                      // Tagline
                      Text(
                        '오늘 점심은 너야!',
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 48.h),
                      // 로딩 도트 애니메이션
                      _LoadingDots(controller: _scaleController),
                    ],
                  ),
                ),
              ),
              // 하단 버전 정보
              Positioned(
                bottom: 40.h,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: Text(
                      'v.${AppConfig.appVersion}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6C7278),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// 로딩 도트 애니메이션 위젯
class _LoadingDots extends StatelessWidget {
  final AnimationController controller;

  const _LoadingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            // 각 도트마다 다른 타이밍으로 애니메이션
            final phase = (controller.value + (index * 0.15)) % 1.0;
            final wave = math.sin(phase * math.pi);
            final scale = 0.7 + (0.3 * wave);
            final opacity = 0.5 + (0.5 * wave);

            return Container(
              margin: EdgeInsets.symmetric(horizontal: 5.w),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(
                      (opacity * 255).toInt(),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
