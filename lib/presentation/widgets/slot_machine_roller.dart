import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../mock/restaurant_model.dart';
import '../../core/theme/app_colors.dart';

class SlotMachineRoller extends StatefulWidget {
  final List<RestaurantModel> restaurants;
  final RestaurantModel finalRestaurant;
  final VoidCallback? onAnimationComplete;

  const SlotMachineRoller({
    super.key,
    required this.restaurants,
    required this.finalRestaurant,
    this.onAnimationComplete,
  });

  @override
  State<SlotMachineRoller> createState() => _SlotMachineRollerState();
}

class _SlotMachineRollerState extends State<SlotMachineRoller>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Ease out 효과로 점점 느려지는 애니메이션
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward().then((_) {
      if (widget.onAnimationComplete != null) {
        widget.onAnimationComplete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemHeight = 80.h;
    final totalItems = widget.restaurants.length;

    return SizedBox(
      height: itemHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: OverflowBox(
            maxHeight: double.infinity,
            alignment: Alignment.topCenter,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                // 애니메이션 값에 따라 스크롤 위치 계산
                // 여러 바퀴 회전하고 최종 레스토랑에서 멈춤
                // totalItems + 6개의 반복 아이템 + 1개의 finalRestaurant = totalItems + 7
                final scrollValue = _animation.value * (totalItems + 6) * itemHeight;

                return Transform.translate(
                  offset: Offset(0, -scrollValue),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 반복해서 보여줄 레스토랑 목록
                      for (var i = 0; i < totalItems + 6; i++)
                        _buildRestaurantItem(
                          widget.restaurants[i % totalItems],
                          itemHeight,
                        ),
                      // 마지막에 최종 레스토랑
                      _buildRestaurantItem(widget.finalRestaurant, itemHeight),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantItem(RestaurantModel restaurant, double height) {
    return SizedBox(
      height: height,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                restaurant.name,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.foreground,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              Text(
                restaurant.category,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.mutedForeground,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
