import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/sketch_screen.dart';
import 'screens/history_screen.dart';
import 'services/sketch_provider.dart';
import 'services/ads/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // AdMob SDK 초기화
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
              '/home': (context) => const SketchScreen(),
              '/history': (context) => const HistoryScreen(),
            },
          ),
        );
      },
    );
  }
}
