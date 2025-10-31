import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/constants/friendly_messages.dart';
import 'slot_machine/slot_machine_page.dart';
import 'map/map_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  void _navigateToSlotMachine() {
    setState(() {
      _currentIndex = 1;
    });
  }

  late final List<Widget> _pages = [
    _HomeContent(onNavigateToSlotMachine: _navigateToSlotMachine),
    const SlotMachinePage(),
    const _HistoryPlaceholder(), // 방문 기록 - 준비중
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedForeground,
        selectedFontSize: 12.sp,
        unselectedFontSize: 12.sp,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.casino),
            label: '오늘의 추천',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: '방문 기록',
          ),
        ],
      ),
    );
  }
}

// 홈 화면 내용
class _HomeContent extends StatelessWidget {
  final VoidCallback onNavigateToSlotMachine;

  const _HomeContent({required this.onNavigateToSlotMachine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.spacing6.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 앱 아이콘
                Container(
                  width: 120.w,
                  height: 120.h,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 64.sp,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: AppDimensions.spacing6.h),

                // 타이틀
                Text(
                  FriendlyMessages.homeTitle,
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.foreground,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppDimensions.spacing3.h),

                // 서브타이틀
                Text(
                  FriendlyMessages.homeSubtitle,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppDimensions.spacing8.h),

                // 슬롯머신 버튼
                SizedBox(
                  width: 280.w,
                  child: ElevatedButton(
                    onPressed: onNavigateToSlotMachine,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.primaryForeground,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacing6.w,
                        vertical: AppDimensions.spacing5.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusLg.r),
                      ),
                      elevation: 0, // 그림자 제거
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.casino, size: 24.sp),
                        SizedBox(width: AppDimensions.spacing3.w),
                        Text(
                          '오늘 점심 뽑기!',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: AppDimensions.spacing4.h),

                // 지도 버튼
                SizedBox(
                  width: 280.w,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const MapPage(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacing6.w,
                        vertical: AppDimensions.spacing5.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusLg.r),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 24.sp),
                        SizedBox(width: AppDimensions.spacing2.w),
                        Text(
                          '지도에서 찾기',
                          style: TextStyle(fontSize: 18.sp),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 방문 기록 준비중 화면
class _HistoryPlaceholder extends StatelessWidget {
  const _HistoryPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('방문 기록'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64.sp,
              color: AppColors.mutedForeground,
            ),
            SizedBox(height: 16.h),
            Text(
              '준비중입니다',
              style: TextStyle(
                fontSize: 18.sp,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
