import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../config/app_theme.dart';
import '../models/sketch_result.dart';
import '../services/sketch_provider.dart';
import '../utils/app_messages.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 히스토리 로드 (비로그인 사용자도 사용 가능, 3일 이상 된 데이터는 자동 필터링)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SketchProvider>().loadHistory(refresh: true);
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SketchProvider>().loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '히스토리',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.onSurface,
            size: 22.sp,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<SketchProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingHistory && provider.history.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            );
          }

          // TODO: 로그인 기능 구현 후 로그인 여부 확인
          final isLoggedIn = false; // 임시: 로그인 기능 구현 후 실제 상태 확인
          
          // 서버에서 이미 비로그인 사용자의 3일 이상 된 데이터를 필터링함
          // 클라이언트에서 추가 필터링은 필요 없지만, 나중에 로그인 기능 구현 시
          // 로그인 사용자는 모든 데이터를 볼 수 있도록 할 예정
          final filteredHistory = provider.history;

          if (filteredHistory.isEmpty) {
            return _EmptyState(isLoggedIn: isLoggedIn);
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadHistory(refresh: true),
            color: AppTheme.primaryColor,
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(20.w),
              itemCount: filteredHistory.length +
                  (provider.hasMoreHistory ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= filteredHistory.length) {
                  return Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  );
                }

                final history = filteredHistory[index];
                // 디버그: 히스토리 데이터 확인
                debugPrint('[HistoryScreen] history[$index]: id=${history.id}, recommendation=${history.recommendation != null}, analysis=${history.analysis != null}');
                if (history.recommendation != null) {
                  debugPrint('[HistoryScreen] recommendation.primary: name=${history.recommendation!.primary.name}, imageUrl=${history.recommendation!.primary.imageUrl}, category=${history.recommendation!.primary.category}');
                } else {
                  debugPrint('[HistoryScreen] recommendation is NULL!');
                }
                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _HistoryCard(
                    history: history,
                    onTap: () {
                      debugPrint('[HistoryScreen] Card tapped! id=${history.id}');
                      // 히스토리 클릭 시 결과 화면으로 이동
                      if (history.recommendation != null && history.analysis != null) {
                        debugPrint('[HistoryScreen] Navigating to ResultScreen...');
                        // 이미지 URL 확인용 디버그 로그
                        final primaryImageUrl = history.recommendation!.primary.imageUrl;
                        debugPrint('[HistoryScreen] Primary imageUrl: $primaryImageUrl');
                        debugPrint('[HistoryScreen] Primary imageUrl isNotEmpty: ${primaryImageUrl?.isNotEmpty ?? false}');
                        final sketchResult = SketchResult(
                          sketchId: history.id,
                          analysis: history.analysis!,
                          recommendation: history.recommendation!,
                          createdAt: history.createdAt,
                        );
                        // SketchResult 생성 후에도 이미지 URL 확인
                        debugPrint('[HistoryScreen] After creating SketchResult, primary imageUrl: ${sketchResult.recommendation.primary.imageUrl}');
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ResultScreen(result: sketchResult),
                          ),
                        );
                      } else {
                        debugPrint('[HistoryScreen] Cannot navigate: recommendation=${history.recommendation != null}, analysis=${history.analysis != null}');
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isLoggedIn;

  const _EmptyState({this.isLoggedIn = false});

  @override
  Widget build(BuildContext context) {
    // 비로그인 사용자이고 3일 이상 된 데이터만 있는 경우 안내 메시지
    if (!isLoggedIn) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history_rounded,
                size: 80.sp,
                color: AppTheme.textDisabled,
              ),
              SizedBox(height: 24.h),
              Text(
                AppMessages.historyEmpty,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '비로그인 사용자는 최근 3일간의 기록만\n조회할 수 있어요.\n\n더 오래 보관하려면 로그인해 주세요!',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 14.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.brush_rounded, color: Colors.white, size: 18.sp),
                      SizedBox(width: 8.w),
                      Text(
                        '그림 그리러 가기',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 80.sp,
              color: AppTheme.textDisabled,
            ),
            SizedBox(height: 24.h),
            Text(
              AppMessages.historyEmpty,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              AppMessages.historyEmptyDescription,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 14.h,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.brush_rounded, color: Colors.white, size: 18.sp),
                    SizedBox(width: 8.w),
                    Text(
                      '그림 그리러 가기',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final SketchHistory history;
  final VoidCallback? onTap;

  const _HistoryCard({required this.history, this.onTap});

  @override
  Widget build(BuildContext context) {
    final analysis = history.analysis;
    final recommendation = history.recommendation;
    final primaryMenu = recommendation?.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // 메뉴 이미지 또는 카테고리 아이콘
                      Container(
                        width: 48.w,
                        height: 48.w,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildMenuImage(primaryMenu?.imageUrl, primaryMenu?.category                        ),
                      ),
                      SizedBox(width: 12.w),
                      if (primaryMenu != null)
                        Flexible(
                          child: Text(
                            primaryMenu.name,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _formatDate(history.createdAt),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textDisabled,
                      size: 18.sp,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Emotion
            if (analysis != null)
              Text(
                analysis.emotion,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.onSurface,
                ),
              ),
            SizedBox(height: 8.h),

            // Keywords
            if (analysis != null && analysis.keywords.isNotEmpty)
              Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: analysis.keywords.map((keyword) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      keyword,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  );
                }).toList(),
              ),

            // Recommendation reason
            if (primaryMenu != null) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant.withAlpha(128),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  primaryMenu.reason,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMenuImage(String? imageUrl, String? category) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppTheme.surfaceVariant,
          child: Center(
            child: Icon(
              _getCategoryIcon(category),
              size: 24.sp,
              color: AppTheme.primaryColor.withAlpha(128),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: AppTheme.surfaceVariant,
          child: Center(
            child: Icon(
              _getCategoryIcon(category),
              size: 24.sp,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      );
    }

    return Container(
      color: AppTheme.primaryColor.withAlpha(26),
      child: Center(
        child: Icon(
          _getCategoryIcon(category),
          size: 24.sp,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}분 전';
      }
      return '${diff.inHours}시간 전';
    } else if (diff.inDays == 1) {
      return '어제';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
