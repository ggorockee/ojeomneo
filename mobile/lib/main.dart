import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/sketch_screen.dart';
import 'screens/history_screen.dart';
import 'services/sketch_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OjeomeoApp());
}

class OjeomeoApp extends StatelessWidget {
  const OjeomeoApp({super.key});

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
              '/home': (context) => const SketchScreen(),
              '/history': (context) => const HistoryScreen(),
            },
          ),
        );
      },
    );
  }
}
