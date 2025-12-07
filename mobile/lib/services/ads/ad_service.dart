import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import 'app_open_ad_manager.dart';
import 'interstitial_ad_manager.dart';

/// AdMob 광고 서비스
/// 앱 전체 광고 초기화 및 관리
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;
  late AppOpenAdManager _appOpenAdManager;
  late InterstitialAdManager _interstitialAdManager;

  /// 광고 초기화 여부
  bool get isInitialized => _isInitialized;

  /// 앱 오프닝 광고 매니저
  AppOpenAdManager get appOpenAdManager => _appOpenAdManager;

  /// 전면광고 매니저
  InterstitialAdManager get interstitialAdManager => _interstitialAdManager;

  /// AdMob SDK 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();

      // 테스트 모드 설정 (디버그 빌드에서만)
      if (kDebugMode && AdConfig.isTestMode) {
        MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(
            testDeviceIds: ['YOUR_TEST_DEVICE_ID'], // 실제 테스트 기기 ID로 교체
          ),
        );
      }

      // 광고 매니저 초기화
      _appOpenAdManager = AppOpenAdManager();
      _interstitialAdManager = InterstitialAdManager();

      // 전면광고 미리 로드
      _interstitialAdManager.loadAd();

      _isInitialized = true;
      debugPrint('[AdService] AdMob SDK initialized successfully');
    } catch (e) {
      debugPrint('[AdService] Failed to initialize AdMob SDK: $e');
    }
  }

  /// 앱 라이프사이클 상태 변경 처리
  void onAppStateChanged(AppLifecycleState state) {
    if (!_isInitialized) return;

    if (state == AppLifecycleState.resumed) {
      _appOpenAdManager.showAdIfAvailable();
    } else if (state == AppLifecycleState.paused) {
      _appOpenAdManager.recordBackgroundTime();
    }
  }

  /// 분석 완료 후 전면광고 표시 (조건부)
  Future<bool> showInterstitialAfterAnalysis() async {
    if (!_isInitialized) return false;
    return _interstitialAdManager.showAdIfReady();
  }

  /// 리소스 해제
  void dispose() {
    if (_isInitialized) {
      _appOpenAdManager.dispose();
      _interstitialAdManager.dispose();
    }
  }
}
