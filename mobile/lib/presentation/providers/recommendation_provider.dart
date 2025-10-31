import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../mock/restaurant_model.dart';
import '../mock/mock_restaurants.dart';
import '../../core/constants/app_constants.dart';

// 추천 상태
enum RecommendationStatus {
  initial,
  loading,
  success,
  error,
}

// 추천 결과 상태
class RecommendationState {
  final RecommendationStatus status;
  final RestaurantModel? restaurant;
  final String? errorMessage;
  final String strategy; // weather, distance, random

  const RecommendationState({
    required this.status,
    this.restaurant,
    this.errorMessage,
    this.strategy = AppConstants.strategyToday,
  });

  RecommendationState copyWith({
    RecommendationStatus? status,
    RestaurantModel? restaurant,
    String? errorMessage,
    String? strategy,
  }) {
    return RecommendationState(
      status: status ?? this.status,
      restaurant: restaurant ?? this.restaurant,
      errorMessage: errorMessage ?? this.errorMessage,
      strategy: strategy ?? this.strategy,
    );
  }
}

// 추천 Provider
class RecommendationNotifier extends StateNotifier<RecommendationState> {
  RecommendationNotifier()
      : super(const RecommendationState(
          status: RecommendationStatus.initial,
          strategy: AppConstants.strategyToday,
        ));

  // 추천 전략 변경
  void setStrategy(String strategy) {
    state = state.copyWith(strategy: strategy);
  }

  // 추천 시작
  Future<void> recommend() async {
    try {
      // 먼저 추천할 레스토랑을 선택
      final nearbyRestaurants =
          MockRestaurants.getByDistance(AppConstants.defaultDistance.toDouble());

      final RestaurantModel restaurant;
      if (nearbyRestaurants.isEmpty) {
        restaurant = MockRestaurants.getRandom();
      } else {
        restaurant = nearbyRestaurants[
            DateTime.now().millisecondsSinceEpoch %
                nearbyRestaurants.length];
      }

      // 선택된 레스토랑과 함께 loading 상태로 변경
      state = state.copyWith(
        status: RecommendationStatus.loading,
        restaurant: restaurant,
      );

      // 슬롯머신 애니메이션 시간을 위한 딜레이
      await Future.delayed(const Duration(milliseconds: 3000));

      // 애니메이션 완료 후 success 상태로 변경
      state = state.copyWith(
        status: RecommendationStatus.success,
      );
    } catch (e) {
      state = state.copyWith(
        status: RecommendationStatus.error,
        errorMessage: '추천 중 오류가 발생했습니다',
      );
    }
  }

  // 초기화
  void reset() {
    state = const RecommendationState(
      status: RecommendationStatus.initial,
      strategy: AppConstants.strategyToday,
    );
  }
}

// Provider 인스턴스
final recommendationProvider =
    StateNotifierProvider<RecommendationNotifier, RecommendationState>((ref) {
  return RecommendationNotifier();
});
