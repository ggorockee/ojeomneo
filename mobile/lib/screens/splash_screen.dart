import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../config/app_theme.dart';

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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

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

    // 화면 전환
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
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
      backgroundColor: AppTheme.surfaceColor,
      body: AnimatedBuilder(
        animation: Listenable.merge([_fadeController, _scaleController]),
        builder: (context, child) {
          return Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 로고 with 크기 애니메이션
                  Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 160,
                      height: 160,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Tagline
                  const Text(
                    '오늘 점심은 너야!',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // 로딩 도트 애니메이션
                  _LoadingDots(controller: _scaleController),
                ],
              ),
            ),
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
              margin: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha((opacity * 255).toInt()),
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
