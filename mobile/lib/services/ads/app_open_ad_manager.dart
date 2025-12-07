import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// 앱 오프닝 광고 매니저
/// 백그라운드 복귀 시 광고 표시
class AppOpenAdManager {
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  bool _isLoadingAd = false;

  DateTime? _lastShowTime;
  DateTime? _backgroundTime;

  /// 광고 로드
  void loadAd() {
    if (_isLoadingAd || _appOpenAd != null) return;

    _isLoadingAd = true;

    AppOpenAd.load(
      adUnitId: AdConfig.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isLoadingAd = false;
          debugPrint('[AppOpenAdManager] Ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          _isLoadingAd = false;
          debugPrint('[AppOpenAdManager] Failed to load ad: ${error.message}');
        },
      ),
    );
  }

  /// 백그라운드 진입 시간 기록
  void recordBackgroundTime() {
    _backgroundTime = DateTime.now();
  }

  /// 광고 표시 가능 여부 확인
  bool get isAdAvailable => _appOpenAd != null && !_isShowingAd;

  /// 쿨다운 확인 (마지막 표시로부터 설정된 시간이 지났는지)
  bool _isCooldownPassed() {
    if (_lastShowTime == null) return true;

    final hoursSinceLastShow =
        DateTime.now().difference(_lastShowTime!).inHours;
    return hoursSinceLastShow >= AdConfig.appOpenCooldownHours;
  }

  /// 최소 백그라운드 시간 확인
  bool _isMinBackgroundTimePassed() {
    if (_backgroundTime == null) return false;

    final secondsInBackground =
        DateTime.now().difference(_backgroundTime!).inSeconds;
    return secondsInBackground >= AdConfig.appOpenMinBackgroundSeconds;
  }

  /// 조건 충족 시 광고 표시
  void showAdIfAvailable() {
    if (!isAdAvailable) {
      loadAd();
      return;
    }

    if (!_isCooldownPassed()) {
      debugPrint('[AppOpenAdManager] Cooldown not passed, skipping ad');
      return;
    }

    if (!_isMinBackgroundTimePassed()) {
      debugPrint('[AppOpenAdManager] Min background time not passed');
      return;
    }

    _showAd();
  }

  /// 광고 표시
  void _showAd() {
    if (_appOpenAd == null) return;

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        debugPrint('[AppOpenAdManager] Ad showed');
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        _lastShowTime = DateTime.now();
        ad.dispose();
        _appOpenAd = null;
        loadAd(); // 다음 광고 미리 로드
        debugPrint('[AppOpenAdManager] Ad dismissed');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
        debugPrint('[AppOpenAdManager] Failed to show ad: ${error.message}');
      },
    );

    _appOpenAd!.show();
  }

  /// 리소스 해제
  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }
}
