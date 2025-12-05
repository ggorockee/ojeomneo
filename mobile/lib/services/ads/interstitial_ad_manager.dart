import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// 전면 광고 매니저
/// 분석 완료 후 조건부 광고 표시
class InterstitialAdManager {
  InterstitialAd? _interstitialAd;
  bool _isLoadingAd = false;
  bool _isShowingAd = false;

  int _analysisCount = 0;

  /// 광고 로드
  void loadAd() {
    if (_isLoadingAd || _interstitialAd != null) return;

    _isLoadingAd = true;

    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoadingAd = false;
          debugPrint('[InterstitialAdManager] Ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          _isLoadingAd = false;
          debugPrint(
              '[InterstitialAdManager] Failed to load ad: ${error.message}');
        },
      ),
    );
  }

  /// 광고 표시 가능 여부
  bool get isAdReady => _interstitialAd != null && !_isShowingAd;

  /// 분석 횟수 증가 및 광고 표시 조건 확인
  Future<bool> showAdIfReady() async {
    _analysisCount++;

    // 설정된 간격마다 광고 표시
    if (_analysisCount % AdConfig.interstitialShowInterval != 0) {
      debugPrint(
          '[InterstitialAdManager] Analysis count: $_analysisCount, skipping ad');
      return false;
    }

    if (!isAdReady) {
      debugPrint('[InterstitialAdManager] Ad not ready');
      loadAd();
      return false;
    }

    return _showAd();
  }

  /// 강제 광고 표시 (조건 무시)
  Future<bool> forceShowAd() async {
    if (!isAdReady) {
      loadAd();
      return false;
    }
    return _showAd();
  }

  /// 광고 표시
  Future<bool> _showAd() async {
    if (_interstitialAd == null) return false;

    final completer = ValueNotifier<bool?>(null);

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        debugPrint('[InterstitialAdManager] Ad showed');
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _interstitialAd = null;
        loadAd(); // 다음 광고 미리 로드
        completer.value = true;
        debugPrint('[InterstitialAdManager] Ad dismissed');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _interstitialAd = null;
        loadAd();
        completer.value = false;
        debugPrint(
            '[InterstitialAdManager] Failed to show ad: ${error.message}');
      },
    );

    _interstitialAd!.show();

    // 광고가 닫힐 때까지 대기
    while (completer.value == null) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return completer.value!;
  }

  /// 분석 횟수 리셋
  void resetAnalysisCount() {
    _analysisCount = 0;
  }

  /// 리소스 해제
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
