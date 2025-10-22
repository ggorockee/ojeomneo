import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/constants/friendly_messages.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/slot-machine');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryForeground,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacing8.w,
                      vertical: AppDimensions.spacing5.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusXl.r),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.casino, size: 32.sp),
                      SizedBox(width: AppDimensions.spacing3.w),
                      Text(
                        '오늘 점심 뽑기!',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppDimensions.spacing4.h),

                // 지도 버튼 (나중에 구현)
                OutlinedButton(
                  onPressed: null, // 나중에 지도 SDK 추가 후 활성화
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacing6.w,
                      vertical: AppDimensions.spacing4.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLg.r),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map, size: 24.sp),
                      SizedBox(width: AppDimensions.spacing2.w),
                      Text(
                        '지도에서 찾기 (준비중)',
                        style: TextStyle(fontSize: 16.sp),
                      ),
                    ],
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
