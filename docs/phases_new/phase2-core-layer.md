# Phase 2: Core 레이어 구현

> 🎯 **목표**: 테마, 상수, 유틸리티 구현 (환경설정 제외)

## 📋 작업 목록

### 2.1 테마 설정 (`.claude/global.css` 기반)
- [ ] `lib/core/theme/app_colors.dart` 생성
  ```dart
  import 'package:flutter/material.dart';
  
  class AppColors {
    // Primary Color (오렌지 계열)
    static const primary = Color(0xFFFF8844);  // oklch(0.7040 0.1910 22.2160)
    static const primaryForeground = Color(0xFFFBFBFB);  // oklch(0.9850 0 0)
    
    // Background
    static const background = Color(0xFFFFFFFF);  // oklch(1 0 0)
    static const foreground = Color(0xFF252525);  // oklch(0.1450 0 0)
    
    // Card
    static const card = Color(0xFFFFFFFF);  // oklch(1 0 0)
    static const cardForeground = Color(0xFF252525);  // oklch(0.1450 0 0)
    
    // Muted
    static const muted = Color(0xFFF8F8F8);  // oklch(0.9700 0 0)
    static const mutedForeground = Color(0xFF8E8E8E);  // oklch(0.5560 0 0)
    
    // Border
    static const border = Color(0xFFEBEBEB);  // oklch(0.9220 0 0)
    
    // Destructive
    static const destructive = Color(0xFFFF5A5A);
    
    // Success
    static const success = Color(0xFF00C896);
  }
  ```

- [ ] `lib/core/theme/app_dimensions.dart` 생성
  ```dart
  class AppDimensions {
    // Border Radius
    static const double radiusSm = 6.0;
    static const double radiusMd = 8.0;
    static const double radiusLg = 10.0;
    static const double radiusXl = 14.0;
    
    // Spacing
    static const double spacing1 = 4.0;
    static const double spacing2 = 8.0;
    static const double spacing3 = 12.0;
    static const double spacing4 = 16.0;
    static const double spacing5 = 20.0;
    static const double spacing6 = 24.0;
    static const double spacing8 = 32.0;
  }
  ```

- [ ] `lib/core/theme/app_text_styles.dart` 생성
  ```dart
  import 'package:flutter/material.dart';
  import 'app_colors.dart';
  
  class AppTextStyles {
    static const String fontFamily = 'Pretendard';
    
    // Font Sizes
    static const double fontSizeSmall = 12.0;
    static const double fontSizeBase = 14.0;
    static const double fontSizeMedium = 16.0;
    static const double fontSizeLarge = 18.0;
    static const double fontSizeXLarge = 20.0;
    static const double fontSizeTitle = 24.0;
    
    // Text Styles
    static const TextStyle title = TextStyle(
      fontSize: fontSizeTitle,
      fontWeight: FontWeight.bold,
      color: AppColors.foreground,
    );
    
    static const TextStyle subtitle = TextStyle(
      fontSize: fontSizeLarge,
      fontWeight: FontWeight.w600,
      color: AppColors.foreground,
    );
    
    static const TextStyle body = TextStyle(
      fontSize: fontSizeMedium,
      fontWeight: FontWeight.normal,
      color: AppColors.foreground,
    );
    
    static const TextStyle caption = TextStyle(
      fontSize: fontSizeSmall,
      fontWeight: FontWeight.normal,
      color: AppColors.mutedForeground,
    );
  }
  ```

- [ ] `lib/core/theme/app_theme.dart` 생성
  ```dart
  import 'package:flutter/material.dart';
  import 'app_colors.dart';
  import 'app_dimensions.dart';
  
  class AppTheme {
    static ThemeData get lightTheme {
      return ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.primaryForeground,
          background: AppColors.background,
          onBackground: AppColors.foreground,
          surface: AppColors.card,
          onSurface: AppColors.cardForeground,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.foreground,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.primaryForeground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing6,
              vertical: AppDimensions.spacing4,
            ),
          ),
        ),
      );
    }
  }
  ```

### 2.2 상수 정의
- [ ] `lib/core/constants/app_constants.dart` 생성
  ```dart
  class AppConstants {
    static const String appName = '오점너';
    static const String appSubtitle = '오늘 점심은 너야!';
    
    // 거리 옵션
    static const List<int> distanceOptions = [100, 500, 1000, 2000];
    static const int defaultDistance = 500;
    
    // 추천 전략
    static const String strategyWeather = 'weather';
    static const String strategyDistance = 'distance';
    static const String strategyRandom = 'random';
  }
  ```

- [ ] `lib/core/constants/friendly_messages.dart` 생성
  ```dart
  class FriendlyMessages {
    // 홈 화면
    static const String homeTitle = '오늘 점심\n뭐 먹을까요?';
    static const String homeSubtitle = '배고프면 일도 안 되지! 빨리 골라볼까?';
    
    // 슬롯머신
    static const String slotMachineTitle = '오늘의 점심을 추천받아보세요!';
    static const String slotMachineLoading = '추천 중입니다...';
    static const String slotMachineResult = '오늘은!';
    
    // 추천 이유
    static const String recommendWeather = '오늘 같은 날씨엔 이게 최고예요!';
    static const String recommendDistance = '여기 바로 근처인데 맛있대요!';
    static const String recommendRandom = '새로운 도전! 여기 가볼래요?';
    
    // 에러
    static const String errorGeneral = '앗! 잠깐 문제가 생겼어요';
    static const String errorNetwork = '인터넷 연결을 확인해주세요!';
    static const String errorLocation = '위치 정보를 켜주시면 더 정확해요!';
    
    // 방문 기록
    static const String visitSaved = '방문 기록이 저장되었습니다!';
    static const String noVisitHistory = '아직 방문 기록이 없어요';
  }
  ```

### 2.3 에러 처리
- [ ] `lib/core/errors/failures.dart` 생성
  ```dart
  abstract class Failure {
    final String message;
    const Failure(this.message);
  }
  
  class ServerFailure extends Failure {
    const ServerFailure(super.message);
  }
  
  class CacheFailure extends Failure {
    const CacheFailure(super.message);
  }
  
  class NetworkFailure extends Failure {
    const NetworkFailure(super.message);
  }
  
  class LocationFailure extends Failure {
    const LocationFailure(super.message);
  }
  ```

- [ ] `lib/core/errors/exceptions.dart` 생성
  ```dart
  class ServerException implements Exception {
    final String message;
    const ServerException(this.message);
  }
  
  class CacheException implements Exception {
    final String message;
    const CacheException(this.message);
  }
  
  class NetworkException implements Exception {
    final String message;
    const NetworkException(this.message);
  }
  
  class LocationException implements Exception {
    final String message;
    const LocationException(this.message);
  }
  ```

### 2.4 유틸리티
- [ ] `lib/core/utils/logger.dart` 생성
  ```dart
  class Logger {
    static void debug(String message) {
      print('[DEBUG] $message');
    }
    
    static void error(String message, [Object? error, StackTrace? stackTrace]) {
      print('[ERROR] $message');
      if (error != null) print('Error: $error');
      if (stackTrace != null) print('StackTrace: $stackTrace');
    }
  }
  ```

- [ ] `lib/core/utils/date_formatter.dart` 생성
  ```dart
  class DateFormatter {
    static String formatRelative(DateTime date) {
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) return '오늘';
      if (difference.inDays == 1) return '어제';
      if (difference.inDays < 7) return '${difference.inDays}일 전';
      if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}주 전';
      return '${(difference.inDays / 30).floor()}개월 전';
    }
  }
  ```

### 2.5 main.dart 업데이트
- [ ] `lib/main.dart`에 테마 적용
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'core/theme/app_theme.dart';
  
  void main() {
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  }
  
  class MyApp extends StatelessWidget {
    const MyApp({super.key});
  
    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: '오점너',
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: Text('오점너 - 오늘 점심은 너야!'),
          ),
        ),
      );
    }
  }
  ```

## 📝 주요 파일

| 파일 경로 | 설명 |
|-----------|------|
| `lib/core/theme/app_theme.dart` | 앱 테마 정의 |
| `lib/core/theme/app_colors.dart` | 색상 시스템 |
| `lib/core/constants/friendly_messages.dart` | 친근한 메시지 |

## 🎯 완료 조건

- ✅ 테마 시스템 구현 완료
- ✅ 상수 정의 완료
- ✅ 에러 처리 구조 완료
- ✅ 유틸리티 구현 완료
- ✅ main.dart에 테마 적용

## ⚠️ 주의사항

- **환경설정(Config) 제외** → Phase 7에서 구현
- **.env 파일 생성하지 않음** → Phase 7에서 생성

## 🚀 다음 단계

Phase 3: Presentation 레이어 (홈/지도) - Mock 데이터로 UI 구현
