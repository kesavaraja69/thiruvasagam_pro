import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/ad_consent_manager.dart';
import '../utils/ad_helper.dart';
import '../utils/app_open_ad_manager.dart';

/// Loads and shows opt-in rewarded ads. Only one ad is kept in memory and the
/// next one is preloaded after the current ad is dismissed.
class RewardedAdService {
  RewardedAdService._();

  static final RewardedAdService instance = RewardedAdService._();

  RewardedAd? _ad;
  bool _isShowing = false;
  Future<void>? _loadFuture;

  /// Call once at startup. It waits for consent and then preloads an ad.
  void initialize() {
    AdConsentManager.state.addListener(_onConsentChanged);
    if (AdConsentManager.canRequestAds) unawaited(load());
  }

  void _onConsentChanged() {
    if (!AdConsentManager.canRequestAds) {
      // Consent was withdrawn — drop any preloaded rewarded ad so it cannot be
      // shown until the user opts in again.
      _ad?.dispose();
      _ad = null;
      return;
    }
    unawaited(load());
  }

  bool get isAvailable => _ad != null;

  Future<void> load() {
    if (!AdConsentManager.canRequestAds) return Future.value();
    if (_ad != null) return Future.value();
    if (_loadFuture != null) return _loadFuture!;

    final completer = Completer<void>();
    _loadFuture = completer.future;

    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loadFuture = null;
          completer.complete();
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
          _loadFuture = null;
          completer.complete();
        },
      ),
    );

    return completer.future;
  }

  /// Shows an ad, loading one first if necessary. Returns true only when the
  /// user completed enough of the ad to earn the reward.
  Future<bool> showOrLoad() async {
    if (!AdConsentManager.canRequestAds) return false;
    if (_isShowing || AppOpenAdManager.pauseAppOpenAd) return false;

    if (_ad == null) {
      await load().timeout(const Duration(seconds: 10), onTimeout: () {});
    }

    final ad = _ad;
    if (ad == null) return false;

    _ad = null;
    _isShowing = true;
    var rewardEarned = false;
    final result = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        AppOpenAdManager.pauseAppOpenAd = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isShowing = false;
        AppOpenAdManager.markFullScreenAdClosed();
        unawaited(load());
        if (!result.isCompleted) result.complete(rewardEarned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('RewardedAd failed to show: $error');
        ad.dispose();
        _isShowing = false;
        AppOpenAdManager.markFullScreenAdClosed();
        unawaited(load());
        if (!result.isCompleted) result.complete(false);
      },
    );

    ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        rewardEarned = true;
      },
    );

    return result.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () {
        _isShowing = false;
        return rewardEarned;
      },
    );
  }
}
