import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/recommendation_provider.dart';
import '../../mock/mock_restaurants.dart';
import '../../widgets/slot_machine_roller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/constants/friendly_messages.dart';
import '../map/map_page.dart';

class SlotMachinePage extends ConsumerWidget {
  const SlotMachinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationState = ref.watch(recommendationProvider);
    final recommendationNotifier = ref.read(recommendationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 추천'),
        automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.spacing4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 슬롯머신 아이콘
                Container(
                  width: 120.w,
                  height: 120.h,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.casino,
                    size: 64.sp,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: AppDimensions.spacing4.h),

                // 타이틀
                Text(
                  FriendlyMessages.slotMachineTitle,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spacing6),

                // 상태별 UI
                _buildContent(context, recommendationState, recommendationNotifier),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    RecommendationState state,
    RecommendationNotifier notifier,
  ) {
    switch (state.status) {
      case RecommendationStatus.initial:
        return _buildInitialState(context, notifier);
      case RecommendationStatus.loading:
        return _buildLoadingState(context, state);
      case RecommendationStatus.success:
        return _buildSuccessState(context, state, notifier);
      case RecommendationStatus.error:
        return _buildErrorState(context, state, notifier);
    }
  }

  Widget _buildInitialState(
      BuildContext context, RecommendationNotifier notifier) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '두근두근... 어디가 나올까요?',
          style: TextStyle(
            fontSize: 16.sp,
            color: AppColors.mutedForeground,
          ),
        ),
        SizedBox(height: AppDimensions.spacing6.h),
        ElevatedButton(
          onPressed: () {
            notifier.recommend();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.primaryForeground,
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing8.w,
              vertical: AppDimensions.spacing4.h,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl.r),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.casino, size: 32.sp),
              SizedBox(width: AppDimensions.spacing2.w),
              Text(
                '돌려돌려 돌림판!',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context, RecommendationState state) {
    // loading 상태에서는 restaurant가 항상 있어야 함
    if (state.restaurant == null) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 슬롯머신 롤링 애니메이션
        SlotMachineRoller(
          restaurants: MockRestaurants.restaurants,
          finalRestaurant: state.restaurant!,
        ),
        SizedBox(height: AppDimensions.spacing4.h),
        Text(
          FriendlyMessages.slotMachineLoading,
          style: TextStyle(
            fontSize: 16.sp,
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState(BuildContext context, RecommendationState state,
      RecommendationNotifier notifier) {
    final restaurant = state.restaurant!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          FriendlyMessages.slotMachineResult,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: AppDimensions.spacing4.h),

        // 추천 결과 카드
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12.r,
                spreadRadius: 0,
                offset: const Offset(0, 0), // 균일한 그림자
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.spacing4.w),
            child: Column(
              children: [
                // 식당 아이콘
                Container(
                  width: 80.w,
                  height: 80.h,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.restaurant,
                    size: 40.sp,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: AppDimensions.spacing3.h),

                // 식당 이름
                Text(
                  restaurant.name,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppDimensions.spacing2.h),

                // 카테고리와 거리
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      restaurant.category,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const Text(' · '),
                    Icon(Icons.location_on,
                        size: 16.sp, color: AppColors.mutedForeground),
                    Text(
                      restaurant.distanceText,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppDimensions.spacing3.h),

                // 추천 이유
                Container(
                  padding: EdgeInsets.all(AppDimensions.spacing3.w),
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 20.sp,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: AppDimensions.spacing2.w),
                      Flexible(
                        child: Text(
                          FriendlyMessages.recommendToday,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppDimensions.spacing4.h),

                // 카테고리별 지도 보기 버튼
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MapPage(
                          category: restaurant.category,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.map_outlined, size: 20.sp),
                  label: Text(
                    '지도에서 ${restaurant.category} 보기',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary, width: 1.5),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacing4.w,
                      vertical: AppDimensions.spacing3.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd.r),
                    ),
                  ),
                ),
                SizedBox(height: AppDimensions.spacing3.h),

                // 다시 추천 버튼
                ElevatedButton(
                  onPressed: () {
                    notifier.recommend();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryForeground,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacing6.w,
                      vertical: AppDimensions.spacing3.h,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh),
                      SizedBox(width: AppDimensions.spacing2.w),
                      const Text('다시 추천받기'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    RecommendationState state,
    RecommendationNotifier notifier,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 64.sp,
          color: AppColors.destructive,
        ),
        SizedBox(height: AppDimensions.spacing4.h),
        Text(
          state.errorMessage ?? FriendlyMessages.errorGeneral,
          style: TextStyle(fontSize: 16.sp),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppDimensions.spacing4.h),
        ElevatedButton(
          onPressed: () => notifier.recommend(),
          child: const Text('다시 시도'),
        ),
      ],
    );
  }
}
