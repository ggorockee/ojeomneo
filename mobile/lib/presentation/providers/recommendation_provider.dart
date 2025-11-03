import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../mock/restaurant_model.dart';
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

  // 추천 시작 (실제 API 연동 필요)
  Future<void> recommend() async {
    try {
      state = state.copyWith(
        status: RecommendationStatus.loading,
      );

      // TODO: Google Places API로 실제 레스토랑 검색
      // 현재는 임시로 에러 상태 반환
      await Future.delayed(const Duration(milliseconds: 500));

      state = state.copyWith(
        status: RecommendationStatus.error,
        errorMessage: 'Google Places API 연동이 필요합니다',
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
