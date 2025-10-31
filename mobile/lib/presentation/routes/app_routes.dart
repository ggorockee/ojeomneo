import 'package:flutter/material.dart';
import '../pages/main_navigation.dart';

class AppRoutes {
  static const String home = '/';

  static Map<String, WidgetBuilder> routes = {
    home: (context) => const MainNavigation(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // 여기서 필요한 경우 동적 라우팅 처리
    return null;
  }
}
