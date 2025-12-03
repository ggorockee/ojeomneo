import 'package:flutter/material.dart';

import 'services/version_service.dart';
import 'widgets/force_update_dialog.dart';

void main() {
  runApp(const OjeomeoApp());
}

/// 오점너 앱
class OjeomeoApp extends StatelessWidget {
  const OjeomeoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '오점너',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

/// 스플래시 화면 (버전 체크 수행)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkVersionAndNavigate();
  }

  Future<void> _checkVersionAndNavigate() async {
    // 최소 1.5초 대기 (스플래시 표시)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // 버전 체크
    final versionInfo = await VersionService.checkVersion();

    if (!mounted) return;

    // 강제 업데이트 필요 여부 확인
    if (versionInfo != null && versionInfo.forceUpdate) {
      // 강제 업데이트 다이얼로그 표시
      await ForceUpdateDialog.show(context, versionInfo);
      // 다이얼로그가 닫히지 않으므로 여기 도달하지 않음
      return;
    }

    // 홈 화면으로 이동
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 또는 앱 아이콘
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.restaurant_menu,
                size: 64,
                color: Colors.deepPurple.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // 앱 이름
            Text(
              '오점너',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade700,
              ),
            ),
            const SizedBox(height: 8),

            // 태그라인
            Text(
              '오늘 점심 뭐 먹지?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 48),

            // 로딩 인디케이터
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.deepPurple.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 홈 화면 (임시)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('오점너'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text(
          '스케치 화면이 여기에 들어갑니다.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
