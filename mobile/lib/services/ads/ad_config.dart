import 'dart:io';

/// AdMob 광고 설정
/// 플랫폼별 광고 단위 ID 관리
class AdConfig {
  AdConfig._();

  // Android Ad Unit IDs
  static const String _androidBanner1 = 'ca-app-pub-8516861197467665/3618386190';
  static const String _androidBanner2 = 'ca-app-pub-8516861197467665/2786959754';
  static const String _androidInterstitial = 'ca-app-pub-8516861197467665/6547801861';
  static const String _androidNative = 'ca-app-pub-8516861197467665/9389587628';
  static const String _androidAppOpen = 'ca-app-pub-8516861197467665/5183405842';

  // iOS Ad Unit IDs
  static const String _iosBanner1 = 'ca-app-pub-8516861197467665/4316390195';
  static const String _iosBanner2 = 'ca-app-pub-8516861197467665/2824179273';
  static const String _iosInterstitial = 'ca-app-pub-8516861197467665/1295475189';
  static const String _iosNative = 'ca-app-pub-8516861197467665/1763035585';
  static const String _iosAppOpen = 'ca-app-pub-8516861197467665/1511097605';

  // 테스트용 Ad Unit IDs (개발 시 사용)
  static const String _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testNative = 'ca-app-pub-3940256099942544/2247696110';
  static const String _testAppOpen = 'ca-app-pub-3940256099942544/9257395921';

  // 테스트 모드 여부 (개발 중에는 true로 설정)
  static const bool isTestMode = false;

  /// 배너 광고 ID (결과 화면용)
  static String get bannerAdUnitId {
    if (isTestMode) return _testBanner;
    return Platform.isAndroid ? _androidBanner1 : _iosBanner1;
  }

  /// 배너 광고 ID 2 (히스토리 화면용)
  static String get banner2AdUnitId {
    if (isTestMode) return _testBanner;
    return Platform.isAndroid ? _androidBanner2 : _iosBanner2;
  }

  /// 전면 광고 ID
  static String get interstitialAdUnitId {
    if (isTestMode) return _testInterstitial;
    return Platform.isAndroid ? _androidInterstitial : _iosInterstitial;
  }

  /// 네이티브 광고 ID
  static String get nativeAdUnitId {
    if (isTestMode) return _testNative;
    return Platform.isAndroid ? _androidNative : _iosNative;
  }

  /// 앱 오프닝 광고 ID
  static String get appOpenAdUnitId {
    if (isTestMode) return _testAppOpen;
    return Platform.isAndroid ? _androidAppOpen : _iosAppOpen;
  }

  // 광고 표시 정책 설정

  /// 전면광고 표시 간격 (분석 횟수)
  static const int interstitialShowInterval = 2;

  /// 앱 오프닝 광고 최소 백그라운드 시간 (초)
  static const int appOpenMinBackgroundSeconds = 60;

  /// 앱 오프닝 광고 쿨다운 시간 (시간)
  static const int appOpenCooldownHours = 4;
}
