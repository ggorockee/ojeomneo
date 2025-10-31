import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';
import 'core/theme/app_theme.dart';
import 'presentation/routes/app_routes.dart';

void main() async {
  // main() 함수를 비동기로 실행시키기 위해서는 WidgetsFlutterBinding.ensureInitialized(); 함수를 호출해야 합니다.
  WidgetsFlutterBinding.ensureInitialized();

  // KakaoMapSdk.instance.initialize 함수로 애플리케이션을 인증합니다.
  await KakaoMapSdk.instance.initialize('3787e943039af49f7b5f216c2823734a');
  print('✅ [main] 카카오맵 SDK 초기화 완료');

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
