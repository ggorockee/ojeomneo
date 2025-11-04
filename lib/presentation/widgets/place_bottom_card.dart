import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../mock/restaurant_model.dart';

/// 구글맵 스타일 하단 장소 카드
class PlaceBottomCard extends StatelessWidget {
  final RestaurantModel restaurant;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const PlaceBottomCard({
    super.key,
    required this.restaurant,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들
            Container(
              margin: EdgeInsets.only(top: 8.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  // 장소 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 장소명
                        Text(
                          restaurant.name,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),

                        // 카테고리 & 거리
                        Row(
                          children: [
                            Text(
                              restaurant.category,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                            Text(
                              ' · ',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                            Icon(
                              Icons.location_on,
                              size: 14.sp,
                              color: AppColors.mutedForeground,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              restaurant.distanceText,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),

                        // 평점
                        if (restaurant.rating > 0)
                          Row(
                            children: [
                              Icon(Icons.star, size: 16.sp, color: Colors.amber),
                              SizedBox(width: 4.w),
                              Text(
                                restaurant.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.foreground,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            '평점 없음',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 닫기 버튼
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(
                      Icons.close,
                      color: AppColors.mutedForeground,
                      size: 24.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
