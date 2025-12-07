import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../config/app_theme.dart';
import '../models/sketch_result.dart';
import '../models/recommendation.dart';
import '../services/ads/banner_ad_widget.dart';

class ResultScreen extends StatefulWidget {
  final SketchResult result;
  final MenuRecommendation? selectedMenu;
  final bool isFromAlternative;

  const ResultScreen({
    super.key,
    required this.result,
    this.selectedMenu,
    this.isFromAlternative = false,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late MenuRecommendation _currentMenu;

  List<MenuRecommendation> get _allMenus {
    final list = <MenuRecommendation>[widget.result.recommendation.primary];
    list.addAll(widget.result.recommendation.alternatives);
    return list;
  }

  @override
  void initState() {
    super.initState();
    _currentMenu = widget.selectedMenu ?? widget.result.recommendation.primary;
    // 디버그: 이미지 URL 확인
    debugPrint('[ResultScreen] initState - primary imageUrl: ${widget.result.recommendation.primary.imageUrl}');
    debugPrint('[ResultScreen] initState - primary imageUrl isNotEmpty: ${widget.result.recommendation.primary.imageUrl?.isNotEmpty ?? false}');
    debugPrint('[ResultScreen] initState - _currentMenu imageUrl: ${_currentMenu.imageUrl}');
    debugPrint('[ResultScreen] initState - _currentMenu imageUrl isNotEmpty: ${_currentMenu.imageUrl?.isNotEmpty ?? false}');
  }

  void _shareResult() {
    final text = '''
오점너가 추천하는 오늘의 메뉴

${_currentMenu.name}

"${_currentMenu.reason}"

#오점너 #오늘점심뭐먹지 #메뉴추천
''';

    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main card - Key 추가하여 메뉴 변경 시 위젯 재생성
                    _PrimaryMenuCard(
                      key: ValueKey(_currentMenu.menuId),
                      menu: _currentMenu,
                    ),
                    SizedBox(height: 32.h),

                    // 대안 메뉴에서 온 경우: 이전 결과로 돌아가기 버튼 표시
                    if (widget.isFromAlternative) ...[
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 14.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: AppTheme.outlineColor),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_back_rounded,
                                color: AppTheme.onSurfaceVariant,
                                size: 18.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                '이전 결과로 돌아가기',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // 대안 메뉴 추천 - 메인 결과 화면에서만 표시
                    if (!widget.isFromAlternative && _allMenus.where((m) => m.menuId != _currentMenu.menuId).isNotEmpty) ...[
                      Text(
                        '이런 메뉴도 어때요?',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      ..._allMenus
                          .where((m) => m.menuId != _currentMenu.menuId)
                          .take(2)
                          .map(
                            (menu) => Padding(
                              padding: EdgeInsets.only(bottom: 10.h),
                              child: _AlternativeMenuCard(
                                key: ValueKey(menu.menuId),
                                menu: menu,
                                onTap: () {
                                  // 대안 메뉴 클릭 시 새 화면으로 이동
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ResultScreen(
                                        result: widget.result,
                                        selectedMenu: menu,
                                        isFromAlternative: true,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                    ],
                    SizedBox(height: 120.h),
                  ],
                ),
              ),
            ),

            // 배너 광고
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: const BannerAdWidget(bannerType: 1),
            ),
          ],
        ),
      ),

      // Bottom fixed buttons
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppTheme.onSurface,
              size: 22.sp,
            ),
          ),
          Text(
            '추천 결과',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.more_vert_rounded,
              color: AppTheme.onSurface,
              size: 22.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 36.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppTheme.surfaceColor.withAlpha(51),
            AppTheme.surfaceColor,
          ],
          stops: const [0.0, 0.2, 0.4],
        ),
      ),
      child: Row(
        children: [
          // Retry button
          Expanded(
            child: _ActionButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: Icons.refresh_rounded,
              label: '다시 추천',
              isPrimary: false,
            ),
          ),
          SizedBox(width: 12.w),

          // Share button
          Expanded(
            child: _ActionButton(
              onPressed: _shareResult,
              icon: Icons.share_rounded,
              label: '공유하기',
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryMenuCard extends StatelessWidget {
  final MenuRecommendation menu;

  const _PrimaryMenuCard({super.key, required this.menu});

  bool get _hasValidImage =>
      menu.imageUrl != null && menu.imageUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24.r),
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with 4:3 aspect ratio
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              decoration: BoxDecoration(
                color: _getCategoryColor(menu.category).withAlpha(51),
                borderRadius: BorderRadius.circular(16.r),
              ),
              clipBehavior: Clip.antiAlias,
              child: _hasValidImage
                  ? CachedNetworkImage(
                      imageUrl: menu.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _buildPlaceholder(),
                      errorWidget: (context, url, error) =>
                          _buildEmojiPlaceholder(),
                    )
                  : _buildEmojiPlaceholder(),
            ),
          ),
          SizedBox(height: 20.h),

          // Category badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppTheme.outlineColor,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              _getCategoryLabel(menu.category),
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Menu name
          Text(
            menu.name,
            style: TextStyle(
              fontSize: 26.sp,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 12.h),

          // Recommendation reason
          Text(
            menu.reason,
            style: TextStyle(
              fontSize: 15.sp,
              height: 1.7,
              color: const Color(0xFF555555),
            ),
          ),
          SizedBox(height: 20.h),

          // Tags
          if (menu.tags.isNotEmpty)
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: menu.tags.map((tag) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Text(
                    '#$tag',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF444444),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.surfaceVariant,
      child: Center(
        child: SizedBox(
          width: 32.w,
          height: 32.w,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiPlaceholder() {
    return Center(
      child: Icon(
        _getCategoryIcon(menu.category),
        size: 80.sp,
        color: _getCategoryColor(menu.category).withAlpha(200),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'korean':
        return Icons.rice_bowl_rounded;
      case 'japanese':
        return Icons.ramen_dining_rounded;
      case 'chinese':
        return Icons.takeout_dining_rounded;
      case 'western':
        return Icons.dinner_dining_rounded;
      case 'asian':
        return Icons.soup_kitchen_rounded;
      case 'snack':
        return Icons.bakery_dining_rounded;
      case 'cafe':
        return Icons.coffee_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'korean':
        return const Color(0xFFFFF5F0);
      case 'japanese':
        return const Color(0xFFFFF8F0);
      case 'chinese':
        return const Color(0xFFFFF0F0);
      case 'western':
        return const Color(0xFFF5F0FF);
      case 'asian':
        return const Color(0xFFF0FFF5);
      default:
        return AppTheme.surfaceVariant;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'korean':
        return '한식';
      case 'chinese':
        return '중식';
      case 'japanese':
        return '일식';
      case 'western':
        return '양식';
      case 'asian':
        return '아시안';
      case 'snack':
        return '분식';
      case 'cafe':
        return '카페';
      default:
        return '기타';
    }
  }
}

class _AlternativeMenuCard extends StatelessWidget {
  final MenuRecommendation menu;
  final VoidCallback onTap;

  const _AlternativeMenuCard({
    super.key,
    required this.menu,
    required this.onTap,
  });

  bool get _hasValidImage =>
      menu.imageUrl != null && menu.imageUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                color: _getCategoryColor(menu.category),
                borderRadius: BorderRadius.circular(14.r),
              ),
              clipBehavior: Clip.antiAlias,
              child: _hasValidImage
                  ? CachedNetworkImage(
                      imageUrl: menu.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.surfaceVariant,
                      ),
                      errorWidget: (context, url, error) =>
                          _buildSmallPlaceholder(),
                    )
                  : _buildSmallPlaceholder(),
            ),
            SizedBox(width: 14.w),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getCategoryLabel(menu.category),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    menu.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textDisabled,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallPlaceholder() {
    return Center(
      child: Icon(
        _getCategoryIcon(menu.category),
        size: 28.sp,
        color: _getCategoryColor(menu.category).withAlpha(200),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'korean':
        return Icons.rice_bowl_rounded;
      case 'japanese':
        return Icons.ramen_dining_rounded;
      case 'chinese':
        return Icons.takeout_dining_rounded;
      case 'western':
        return Icons.dinner_dining_rounded;
      case 'asian':
        return Icons.soup_kitchen_rounded;
      case 'snack':
        return Icons.bakery_dining_rounded;
      case 'cafe':
        return Icons.coffee_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'korean':
        return const Color(0xFFFFF5F0);
      case 'japanese':
        return const Color(0xFFFFF8F0);
      case 'chinese':
        return const Color(0xFFFFF0F0);
      case 'western':
        return const Color(0xFFF5F0FF);
      case 'asian':
        return const Color(0xFFF0FFF5);
      default:
        return AppTheme.surfaceVariant;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'korean':
        return '한식';
      case 'chinese':
        return '중식';
      case 'japanese':
        return '일식';
      case 'western':
        return '양식';
      case 'asian':
        return '아시안';
      case 'snack':
        return '분식';
      case 'cafe':
        return '카페';
      default:
        return '기타';
    }
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool isPrimary;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 18.h),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          color: AppTheme.toolButtonInactive,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.onSurface, size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
