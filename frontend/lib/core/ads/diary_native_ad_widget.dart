import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:frontend/core/ads/ad_service.dart';
import 'package:frontend/core/theme/app_theme.dart';

/// 300×250 banner ad placed between Dinner and Snacks in the diary page.
class DiaryNativeAdWidget extends StatefulWidget {
  const DiaryNativeAdWidget({super.key});

  @override
  State<DiaryNativeAdWidget> createState() => _DiaryNativeAdWidgetState();
}

class _DiaryNativeAdWidgetState extends State<DiaryNativeAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (!AdService.isSupported) return;

    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.mediumRectangle, // 300×250 — large card matching screenshot
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
          if (kDebugMode) print('Diary mid-section ad loaded.');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (kDebugMode) print('Diary mid-section ad failed: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdService.isSupported || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink(); // nothing shows until ad is ready
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      width: double.infinity,
      height: _bannerAd!.size.height.toDouble(),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
