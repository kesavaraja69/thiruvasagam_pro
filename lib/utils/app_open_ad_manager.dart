// lib/utils/app_open_ad_manager.dart

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_helper.dart';

class AppOpenAdManager {
  // 🚨 1. Add this static global lock!
  static bool pauseAppOpenAd = false;

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  DateTime? _appOpenLoadTime;

  /// Load an AppOpenAd.
  /// Load an AppOpenAd.
  void loadAd() {
    // 🚨 We removed the initialization check here, it will be handled by the Consent Manager!
    AppOpenAd.load(
      adUnitId: AdHelper.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint(
            '✅ AppOpenAd loaded successfully',
          ); // Add a print statement to verify!
          _appOpenLoadTime = DateTime.now();
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ AppOpenAd failed to load: $error');
        },
      ),
      // App Open ads are only meant to be shown in portrait orientation
      // orientation: AppOpenAd.orientationPortrait,
    );
  }

  /// Whether an ad is available to be shown.
  bool get isAdAvailable {
    return _appOpenAd != null &&
        _appOpenLoadTime != null &&
        // Ads timeout after 4 hours, so we check the load time
        DateTime.now().difference(_appOpenLoadTime!) < const Duration(hours: 4);
  }

  /// Shows the ad, if one exists and is not already being shown.
  //   void showAdIfAvailable() {
  //     if (!isAdAvailable) {
  //       loadAd();
  //       return;
  //     }
  //     if (_isShowingAd) return;

  //     _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
  //       onAdShowedFullScreenContent: (ad) {
  //         _isShowingAd = true;
  //       },
  //       onAdFailedToShowFullScreenContent: (ad, error) {
  //         _isShowingAd = false;
  //         ad.dispose();
  //         _appOpenAd = null;
  //       },
  //       onAdDismissedFullScreenContent: (ad) {
  //         _isShowingAd = false;
  //         ad.dispose();
  //         _appOpenAd = null;
  //         loadAd(); // Queue up the next open ad
  //       },
  //     );

  //     _appOpenAd!.show();
  //   }
  // }

  void showAdIfAvailable() {
    if (!isAdAvailable) {
      loadAd();
      return;
    }

    // 🚨 2. If the lock is ON, or we are already showing an ad, STOP!
    if (_isShowingAd || pauseAppOpenAd) {
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
    );

    _appOpenAd!.show();
  }
}

/// Listens for app foreground events to trigger the ad
class AppLifecycleReactor extends WidgetsBindingObserver {
  final AppOpenAdManager appOpenAdManager;

  AppLifecycleReactor({required this.appOpenAdManager});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app is resumed from the background, show the ad!
    if (state == AppLifecycleState.resumed &&
        AppOpenAdManager.pauseAppOpenAd == false) {
      appOpenAdManager.showAdIfAvailable();
    }
  }
}
