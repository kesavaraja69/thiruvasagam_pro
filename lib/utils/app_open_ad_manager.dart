import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/reward_unlock_service.dart';
import 'ad_consent_manager.dart';
import 'ad_helper.dart';

class AppOpenAdManager {
  /// True while any full-screen ad (interstitial/app open) is on screen.
  static bool pauseAppOpenAd = false;

  static int _visibleBannerAds = 0;
  static DateTime? _lastFullScreenAdClosedAt;
  static DateTime? _backgroundedAt;
  static bool _skipNextResume = false;

  /// Ignore short trips to the background (notification shade, permission
  /// dialogs, app switcher) instead of treating every resume as an app open.
  static const Duration _minBackgroundBeforeOpenAd = Duration(seconds: 5);

  /// Never show an app open ad immediately before/after another full-screen
  /// ad.
  static const Duration _postFullScreenCooldown = Duration(seconds: 30);

  static void bannerShown() => _visibleBannerAds++;

  static void bannerHidden() {
    if (_visibleBannerAds > 0) _visibleBannerAds--;
  }

  static void markFullScreenAdClosed() {
    _lastFullScreenAdClosedAt = DateTime.now();
    pauseAppOpenAd = false;
  }

  /// Call before handing the user off to an external app (browser, mail,
  /// share sheet) so returning does not trigger an app open ad.
  static void skipNextResume() => _skipNextResume = true;

  static void markBackgrounded() => _backgroundedAt = DateTime.now();

  /// Consumes the one-shot resume guard and returns whether this resume
  /// qualifies as an app open.
  static bool consumeResume() {
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;

    final skip = _skipNextResume;
    _skipNextResume = false;

    if (skip || backgroundedAt == null) return false;
    return DateTime.now().difference(backgroundedAt) >=
        _minBackgroundBeforeOpenAd;
  }

  static bool get _hasBannerOnScreen => _visibleBannerAds > 0;

  static bool get _inFullScreenCooldown {
    final closedAt = _lastFullScreenAdClosedAt;
    return closedAt != null &&
        DateTime.now().difference(closedAt) < _postFullScreenCooldown;
  }

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  DateTime? _appOpenLoadTime;

  void loadAd() {
    if (!AdConsentManager.canRequestAds) return;

    AppOpenAd.load(
      adUnitId: AdHelper.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AppOpenAd loaded successfully');
          _appOpenLoadTime = DateTime.now();
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('AppOpenAd failed to load: $error');
        },
      ),
    );
  }

  bool get isAdAvailable {
    return _appOpenAd != null &&
        _appOpenLoadTime != null &&
        // Ads time out after four hours.
        DateTime.now().difference(_appOpenLoadTime!) < const Duration(hours: 4);
  }

  void showAdIfAvailable() {
    if (!AdConsentManager.canRequestAds) return;
    if (RewardUnlockService.instance.isAdFree) return;

    if (!isAdAvailable) {
      loadAd();
      return;
    }

    // Do not stack full-screen ads, show over a screen that already contains a
    // banner, or appear during a short background trip.
    if (_isShowingAd ||
        pauseAppOpenAd ||
        _hasBannerOnScreen ||
        _inFullScreenCooldown) {
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        pauseAppOpenAd = true;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        markFullScreenAdClosed();
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        markFullScreenAdClosed();
        loadAd();
      },
    );

    _appOpenAd!.show();
  }
}

/// Shows an app open ad only when the user returns to the app after a real
/// background trip, never after external flows or over a banner screen.
class AppLifecycleReactor extends WidgetsBindingObserver {
  final AppOpenAdManager appOpenAdManager;

  AppLifecycleReactor({required this.appOpenAdManager});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      AppOpenAdManager.markBackgrounded();
      return;
    }

    if (state == AppLifecycleState.resumed &&
        AppOpenAdManager.consumeResume()) {
      appOpenAdManager.showAdIfAvailable();
    }
  }
}
