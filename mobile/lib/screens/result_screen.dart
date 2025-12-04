import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_theme.dart';
import '../models/analysis.dart';
import '../models/sketch_result.dart';
import '../models/recommendation.dart';

class ResultScreen extends StatelessWidget {
  final SketchResult result;

  const ResultScreen({super.key, required this.result});

  void _shareResult(BuildContext context) {
    final primary = result.recommendation.primary;
    final text = '''
오점너가 추천하는 오늘의 메뉴

${primary.name}

"${primary.reason}"

#오점너 #오늘점심뭐먹지 #메뉴추천
''';

    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final primary = result.recommendation.primary;
    final alternatives = result.recommendation.alternatives;
    final analysis = result.analysis;

    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '추천 결과',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: '공유하기',
            onPressed: () => _shareResult(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Primary recommendation - 메인 카드
              _PrimaryMenuCard(menu: primary),
              SizedBox(height: 20.h),

              // Analysis section - 감정 분석
              _AnalysisCard(analysis: analysis),
              SizedBox(height: 24.h),

              // Alternative recommendations
              if (alternatives.isNotEmpty) ...[
                Text(
                  '이런 메뉴도 어때요?',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
                SizedBox(height: 12.h),
                ...alternatives.map(
                  (menu) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: _AlternativeMenuCard(menu: menu),
                  ),
                ),
              ],

              SizedBox(height: 24.h),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).popUntil(
                          (route) => route.isFirst,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        side: BorderSide(
                          color: AppTheme.primaryColor.withAlpha(128),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      icon: Icon(Icons.refresh_rounded, size: 20.sp),
                      label: Text(
                        '다시 그리기',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _shareResult(context),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      icon: Icon(Icons.share_rounded, size: 20.sp),
                      label: Text(
                        '공유하기',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final Analysis analysis;

  const _AnalysisCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.secondaryColor.withAlpha(40),
            AppTheme.tertiaryColor.withAlpha(30),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.secondaryColor.withAlpha(60),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(180),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  analysis.moodEmoji,
                  style: TextStyle(fontSize: 22.sp),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '그림에서 느껴지는 감정',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      analysis.emotion,
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: AppTheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: analysis.keywords.map((keyword) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(200),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withAlpha(20),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  keyword,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PrimaryMenuCard extends StatelessWidget {
  final MenuRecommendation menu;

  const _PrimaryMenuCard({required this.menu});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withAlpha(25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Menu image with gradient overlay
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: menu.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: menu.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _buildPlaceholder(),
                        errorWidget: (context, url, error) =>
                            _buildLogoPlaceholder(),
                      )
                    : _buildLogoPlaceholder(),
              ),
              // Gradient overlay for text readability
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(100),
                      ],
                    ),
                  ),
                ),
              ),
              // Category badge
              Positioned(
                top: 12.h,
                left: 12.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withAlpha(80),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _getCategoryLabel(menu.category),
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Menu name
                Text(
                  menu.name,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 12.h),

                // Recommendation reason
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.surfaceVariant,
                        AppTheme.surfaceVariant.withAlpha(150),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💬',
                        style: TextStyle(fontSize: 18.sp),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          menu.reason,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppTheme.onSurface,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),

                // Tags
                if (menu.tags.isNotEmpty)
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: menu.tags.map((tag) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.tertiaryColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: AppTheme.tertiaryColor.withAlpha(60),
                          ),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
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
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryColor.withAlpha(128),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceVariant,
            AppTheme.tertiaryColor.withAlpha(40),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 80.w,
              height: 80.w,
              opacity: const AlwaysStoppedAnimation(0.7),
            ),
            SizedBox(height: 8.h),
            Text(
              '이미지 준비 중',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
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

  const _AlternativeMenuCard({required this.menu});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12.w),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: SizedBox(
            width: 60.w,
            height: 60.w,
            child: menu.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: menu.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppTheme.surfaceVariant,
                    ),
                    errorWidget: (context, url, error) =>
                        _buildSmallLogoPlaceholder(),
                  )
                : _buildSmallLogoPlaceholder(),
          ),
        ),
        title: Text(
          menu.name,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurface,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Text(
            menu.reason,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.onSurfaceVariant,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildSmallLogoPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceVariant,
            AppTheme.tertiaryColor.withAlpha(30),
          ],
        ),
      ),
      child: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 32.w,
          height: 32.w,
          opacity: const AlwaysStoppedAnimation(0.6),
        ),
      ),
    );
  }
}
