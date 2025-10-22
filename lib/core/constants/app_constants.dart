class AppConstants {
  static const String appName = '오점너';
  static const String appSubtitle = '오늘 점심은 너야!';

  // 거리 옵션
  static const List<int> distanceOptions = [100, 500, 1000, 2000];
  static const int defaultDistance = 500;

  // 추천 전략
  static const String strategyToday = 'today'; // 오늘의 추천 (날씨+거리 통합)
}
