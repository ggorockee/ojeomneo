import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'presentation/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('✅ [main] 앱 초기화 완료');

  // 환경 변수 로드
  await dotenv.load(fileName: ".env");
  debugPrint('✅ [main] 환경 변수 로드 완료');

  // 네이버 지도 초기화
  await FlutterNaverMap().init(
    clientId: '1ounpz7chm',
    onAuthFailed: (ex) {
      switch (ex) {
        case NQuotaExceededException(:final message):
          debugPrint('❌ 네이버 지도 사용량 초과 (message: $message)');
          break;
        case NUnauthorizedClientException():
        case NClientUnspecifiedException():
        case NAnotherAuthFailedException():
          debugPrint('❌ 네이버 지도 인증 실패: $ex');
          break;
      }
    },
  );
  debugPrint('✅ [main] 네이버 지도 초기화 완료');

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
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone 11 Pro 기준
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: '오점너',
          theme: AppTheme.lightTheme,
          initialRoute: AppRoutes.home,
          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  }
}
