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
  late AnimationController _pulseController;
  late AnimationController _colorController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _colorAnimation;

  // 로고에 적용할 색상 필터 (따뜻한 음식 컬러)
  final List<Color> _filterColors = [
    const Color(0xFFFF8C42), // 오렌지
    const Color(0xFFFFAB76), // 피치
    const Color(0xFFFF6B6B), // 코랄
    const Color(0xFFFFC93C), // 골드
    const Color(0xFFFF8C42), // 오렌지 (루프)
  ];

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

    // 펄스 애니메이션 (로고 크기 변화)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 색상 필터 애니메이션
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _colorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _colorController, curve: Curves.linear),
    );

    // 펄스 반복
    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _pulseController.forward();
      }
    });

    // 색상 반복
    _colorController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _colorController.forward(from: 0.0);
      }
    });

    // 애니메이션 시작
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _pulseController.forward();
      _colorController.forward();
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
    _pulseController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Color _getCurrentFilterColor() {
    final totalSegments = _filterColors.length - 1;
    final segmentProgress = _colorAnimation.value * totalSegments;
    final currentIndex = segmentProgress.floor().clamp(0, totalSegments - 1);
    final nextIndex = (currentIndex + 1).clamp(0, totalSegments);
    final localProgress = segmentProgress - currentIndex;

    return Color.lerp(
      _filterColors[currentIndex],
      _filterColors[nextIndex],
      localProgress,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: AnimatedBuilder(
        animation: Listenable.merge([_fadeController, _pulseController, _colorController]),
        builder: (context, child) {
          final filterColor = _getCurrentFilterColor();

          return Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 로고 with 펄스 + 색상 필터
                  Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 글로우 효과 (색상 필터에 맞춰 변화)
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: filterColor.withAlpha(60),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        // 로고 이미지 with 색상 오버레이
                        ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return RadialGradient(
                              center: Alignment.center,
                              radius: 0.8,
                              colors: [
                                filterColor.withAlpha(40),
                                Colors.transparent,
                              ],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcATop,
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 160,
                            height: 160,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Tagline
                  const Text(
                    '오늘 점심 뭐 먹지?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // 로딩 도트 애니메이션
                  _LoadingDots(
                    controller: _pulseController,
                    color: filterColor,
                  ),
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
  final Color color;

  const _LoadingDots({
    required this.controller,
    required this.color,
  });

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
                    color: color.withAlpha((opacity * 255).toInt()),
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
