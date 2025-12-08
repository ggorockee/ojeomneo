import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'sketch_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import '../config/app_theme.dart';

/// MainScreen
/// ------------------------------------------------------
/// 하단 탭 네비게이션 컨테이너
/// - 탭: 홈(스케치) / 기록 / 내정보
/// - 상태 보존: IndexedStack 사용 -> 탭 전환 시 각 화면의 상태 유지
class MainScreen extends StatefulWidget {
  /// 초기 탭 인덱스
  final int initialTabIndex;

  const MainScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// 현재 선택된 탭 인덱스
  int _selectedIndex = 0;

  /// 탭별 화면 (Lazy loading)
  late List<Widget?> _tabs;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;

    // 홈 화면만 미리 로드, 나머지는 lazy loading
    _tabs = [
      const SketchScreen(),
      null, // HistoryScreen - lazy loading
      null, // ProfileScreen - lazy loading
    ];
  }

  /// 탭 전환 핸들러
  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // 같은 탭 재터치 시 무시

    setState(() {
      _selectedIndex = index;

      // Lazy loading: 탭이 처음 선택될 때 화면 생성
      if (index == 1 && _tabs[1] == null) {
        _tabs[1] = const HistoryScreen();
      }
      if (index == 2 && _tabs[2] == null) {
        _tabs[2] = const ProfileScreen();
      }
    });
  }

  /// 뒤로가기 버튼 처리
  Future<bool> _onWillPop() async {
    // 홈 탭이 아니면 홈으로 이동
    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
      return false;
    }

    // 홈 탭에서 뒤로가기 시 앱 종료
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _tabs[0]!,
            _tabs[1] ?? const SizedBox.shrink(),
            _tabs[2] ?? const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 24.sp),
              activeIcon: Icon(Icons.home, size: 24.sp),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined, size: 24.sp),
              activeIcon: Icon(Icons.history, size: 24.sp),
              label: '기록',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 24.sp),
              activeIcon: Icon(Icons.person, size: 24.sp),
              label: '내정보',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: const Color(0xFF6C7278),
          onTap: _onItemTapped,
          showUnselectedLabels: true,
          selectedFontSize: 12.sp,
          unselectedFontSize: 12.sp,
          backgroundColor: Colors.white,
          elevation: 8,
        ),
      ),
    );
  }
}
