import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';

import 'config/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/history_screen.dart';
import 'screens/att_explanation_screen.dart';
import 'services/sketch_provider.dart';
import 'services/ads/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경변수 로드
  await dotenv.load(fileName: '.env');

  // Firebase 초기화
  await Firebase.initializeApp();

  // Kakao SDK 초기화
  final nativeAppKey = dotenv.env['KAKAO_NATIVE_APP_KEY'];
  if (nativeAppKey != null) {
    KakaoSdk.init(nativeAppKey: nativeAppKey);
  }

  // AdMob SDK 초기화
  // ATT 권한은 ATTExplanationScreen에서 처리됨
  await AdService().initialize();

  runApp(const OjeomeoApp());
}

class OjeomeoApp extends StatefulWidget {
  const OjeomeoApp({super.key});

  @override
  State<OjeomeoApp> createState() => _OjeomeoAppState();
}

class _OjeomeoAppState extends State<OjeomeoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AdService().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱 라이프사이클 변경 시 광고 서비스에 알림
    AdService().onAppStateChanged(state);
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X 기준
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SketchProvider()),
          ],
          child: MaterialApp(
            title: '오점너',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/att-explanation': (context) => const ATTExplanationScreen(),
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const MainScreen(),
              '/history': (context) => const HistoryScreen(),
            },
          ),
        );
      },
    );
  }
}
