import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

import 'config/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/history_screen.dart';
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

  // iOS에서 App Tracking Transparency (ATT) 권한 요청
  // AdMob 초기화 전에 반드시 실행되어야 함
  if (Platform.isIOS) {
    try {
      // ATT 권한 상태 확인
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;

      // 아직 권한 요청을 하지 않은 경우에만 요청
      if (status == TrackingStatus.notDetermined) {
        // 사용자에게 ATT 권한 요청 다이얼로그 표시
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (e) {
      // ATT 권한 요청 실패 시에도 앱은 계속 실행
      debugPrint('ATT 권한 요청 실패: $e');
    }
  }

  // AdMob SDK 초기화 (ATT 권한 요청 후에 실행)
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
