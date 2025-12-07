import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// 배너 광고 위젯
/// 결과 화면 하단에 표시
class BannerAdWidget extends StatefulWidget {
  /// 배너 타입 (1: 결과 화면, 2: 히스토리 화면)
  final int bannerType;

  const BannerAdWidget({
    super.key,
    this.bannerType = 1,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adUnitId = widget.bannerType == 1
        ? AdConfig.bannerAdUnitId
        : AdConfig.banner2AdUnitId;

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
          debugPrint('[BannerAdWidget] Ad loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('[BannerAdWidget] Failed to load ad: ${error.message}');
        },
        onAdOpened: (ad) {
          debugPrint('[BannerAdWidget] Ad opened');
        },
        onAdClosed: (ad) {
          debugPrint('[BannerAdWidget] Ad closed');
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      // 광고 로딩 중이거나 실패 시 빈 공간 유지
      return const SizedBox(
        height: 50,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
