import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdLoading = false;

  static RewardedAd? _rewardedAd;
  static bool _isRewardedAdLoading = false;

  // --- Daily cap tracker: feature key → last-shown date string (yyyy-MM-dd) ---
  static final Map<String, String> _dailyCapShownDate = {};

  /// Returns true if the feature's video ad has already been shown today.
  static bool _shownTodayFor(String featureKey) {
    final today = _todayStr();
    return _dailyCapShownDate[featureKey] == today;
  }

  /// Record that a video ad was shown today for [featureKey].
  static void _markShownToday(String featureKey) {
    _dailyCapShownDate[featureKey] = _todayStr();
  }

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Determine if Google Mobile Ads is supported on the current platform.
  static bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Get the Banner Ad Unit ID based on the current platform.
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1237832395857766/9863197121'; // Android Production ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-1237832395857766/9863197121'; // iOS Production ID
    }
    return '';
  }

  /// Get the Interstitial Ad Unit ID based on the current platform.
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1237832395857766/9008601838'; // Android Production ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-1237832395857766/9008601838'; // iOS Production ID
    }
    return '';
  }

  /// Get the Rewarded Ad Unit ID based on the current platform.
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1237832395857766/7592257001'; // Android Production ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-1237832395857766/7592257001'; // iOS Production ID
    }
    return '';
  }

  /// Initialize the Mobile Ads SDK if supported.
  static Future<void> initialize() async {
    if (!isSupported) {
      if (kDebugMode) {
        print('AdMob is not supported on this platform. Running in fallback mode.');
      }
      return;
    }
    try {
      await MobileAds.instance.initialize();
      if (kDebugMode) {
        print('AdMob initialized successfully.');
      }
      // Preload ads
      loadInterstitial();
      loadRewarded();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize AdMob: $e');
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  INTERSTITIAL
  // ─────────────────────────────────────────────────────────────

  /// Load an Interstitial Ad.
  static void loadInterstitial() {
    if (!isSupported || _isInterstitialAdLoading || _interstitialAd != null) {
      return;
    }

    _isInterstitialAdLoading = true;
    if (kDebugMode) print('Loading Interstitial Ad...');

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;
          if (kDebugMode) print('Interstitial Ad loaded successfully.');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              if (kDebugMode) print('Interstitial Ad dismissed.');
              ad.dispose();
              _interstitialAd = null;
              loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              if (kDebugMode) print('Interstitial Ad failed to show: $error');
              ad.dispose();
              _interstitialAd = null;
              loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdLoading = false;
          _interstitialAd = null;
          if (kDebugMode) print('Interstitial Ad failed to load: $error');
        },
      ),
    );
  }

  /// Show the Interstitial Ad if available, then execute [onDismiss].
  static void showInterstitial(void Function() onDismiss) {
    if (!isSupported) {
      onDismiss();
      return;
    }

    if (_interstitialAd != null) {
      final originalCallback = _interstitialAd!.fullScreenContentCallback;
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          originalCallback?.onAdDismissedFullScreenContent?.call(ad);
          onDismiss();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          originalCallback?.onAdFailedToShowFullScreenContent?.call(ad, error);
          onDismiss();
        },
      );
      _interstitialAd!.show();
    } else {
      if (kDebugMode) print('Interstitial Ad was not ready. Executing callback.');
      onDismiss();
      loadInterstitial();
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  REWARDED VIDEO
  // ─────────────────────────────────────────────────────────────

  /// Load a Rewarded Ad.
  static void loadRewarded() {
    if (!isSupported || _isRewardedAdLoading || _rewardedAd != null) {
      return;
    }

    _isRewardedAdLoading = true;
    if (kDebugMode) print('Loading Rewarded Ad...');

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
          if (kDebugMode) print('Rewarded Ad loaded successfully.');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              if (kDebugMode) print('Rewarded Ad dismissed.');
              ad.dispose();
              _rewardedAd = null;
              loadRewarded();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              if (kDebugMode) print('Rewarded Ad failed to show: $error');
              ad.dispose();
              _rewardedAd = null;
              loadRewarded();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoading = false;
          _rewardedAd = null;
          if (kDebugMode) print('Rewarded Ad failed to load: $error');
        },
      ),
    );
  }

  /// Show a rewarded video ad **at most once per calendar day** for [featureKey].
  ///
  /// [featureKey] — unique string per feature, e.g. `'debrief'` or `'weight_trend'`.
  /// [onDismiss]  — called after the ad is dismissed (or skipped if already shown today).
  static void showRewardedOncePerDay(
    String featureKey, {
    void Function()? onDismiss,
  }) {
    if (!isSupported) {
      onDismiss?.call();
      return;
    }

    // Already shown today — skip silently
    if (_shownTodayFor(featureKey)) {
      if (kDebugMode) print('[$featureKey] Rewarded ad already shown today. Skipping.');
      onDismiss?.call();
      return;
    }

    if (_rewardedAd != null) {
      _markShownToday(featureKey);

      final originalCallback = _rewardedAd!.fullScreenContentCallback;
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          originalCallback?.onAdDismissedFullScreenContent?.call(ad);
          onDismiss?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          originalCallback?.onAdFailedToShowFullScreenContent?.call(ad, error);
          onDismiss?.call();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          if (kDebugMode) print('[$featureKey] User earned reward: ${reward.amount} ${reward.type}');
        },
      );
    } else {
      if (kDebugMode) print('[$featureKey] Rewarded Ad not ready. Loading for next time.');
      loadRewarded();
      onDismiss?.call();
    }
  }

  /// Show the Rewarded Ad and execute [onRewardEarned] if user watches it fully.
  static void showRewarded(void Function() onRewardEarned, {void Function()? onFailedToLoad}) {
    if (!isSupported) {
      onRewardEarned();
      return;
    }

    if (_rewardedAd != null) {
      bool rewardEarned = false;

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          rewardEarned = true;
        },
      );

      final originalCallback = _rewardedAd!.fullScreenContentCallback;
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          originalCallback?.onAdDismissedFullScreenContent?.call(ad);
          if (rewardEarned) {
            onRewardEarned();
          } else {
            onFailedToLoad?.call();
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          originalCallback?.onAdFailedToShowFullScreenContent?.call(ad, error);
          onFailedToLoad?.call();
        },
      );
    } else {
      if (kDebugMode) print('Rewarded Ad was not ready.');
      if (onFailedToLoad != null) {
        onFailedToLoad();
      } else {
        onRewardEarned();
      }
      loadRewarded();
    }
  }
}
