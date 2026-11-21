import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/ad_consent_manager.dart';
import '../utils/ad_helper.dart';
import '../utils/app_open_ad_manager.dart';

/// Which reward flow an ad is being prepared for. Each flow has its own
/// candidate units and its own preloaded slot, so the offline-download reward
/// can use download-specific units without disturbing the others.
enum RewardedAdPurpose { standard, download }

/// AdMob formats that can both return a reward. They are separate formats and
/// cannot be loaded through each other's API.
enum _Format { rewardedInterstitial, rewarded }

/// One preloaded rewarded ad plus the bookkeeping needed to try each candidate
/// unit exactly once per load pass.
class _Slot {
  RewardedInterstitialAd? interstitialAd;
  RewardedAd? rewardedAd;

  Future<void>? loadFuture;

  /// `unitId|format` combinations AdMob rejected with "Ad unit doesn't match
  /// format" (code 3). Permanent for the session — retrying cannot succeed.
  final Set<String> formatMismatches = <String>{};

  bool get hasAd => interstitialAd != null || rewardedAd != null;

  void clear() {
    interstitialAd?.dispose();
    interstitialAd = null;
    rewardedAd?.dispose();
    rewardedAd = null;
  }
}

/// Loads and shows opt-in rewarded ads.
///
/// AdMob treats *rewarded* and *rewarded interstitial* as two distinct formats
/// that cannot be loaded through each other's API: asking for the wrong one
/// fails with `LoadAdError(code: 3, "Ad unit doesn't match format")`. Because a
/// unit's format is a property of the AdMob console entry rather than something
/// the app can see, every candidate unit is tried as a rewarded interstitial
/// first and then as a classic rewarded ad. Units that reject a format are
/// remembered so the failed combination is never retried.
///
/// A load pass walks the candidate list in order, so a unit that returns no
/// fill simply hands over to the next one.
class RewardedAdService {
  RewardedAdService._();

  static final RewardedAdService instance = RewardedAdService._();

  /// AdMob error code for "ad unit doesn't match the requested format".
  static const int _formatMismatchCode = 3;

  final Map<RewardedAdPurpose, _Slot> _slots = {
    for (final purpose in RewardedAdPurpose.values) purpose: _Slot(),
  };

  /// True while any rewarded ad is on screen. Only one is ever shown at a time.
  bool _isShowing = false;

  /// Call once at startup. It waits for consent and then preloads an ad.
  void initialize() {
    AdConsentManager.state.addListener(_onConsentChanged);
    if (AdConsentManager.canRequestAds) unawaited(load());
  }

  void _onConsentChanged() {
    if (!AdConsentManager.canRequestAds) {
      // Consent was withdrawn — drop any preloaded ad so it cannot be shown
      // until the user opts in again.
      for (final slot in _slots.values) {
        slot.clear();
      }
      return;
    }
    unawaited(load());
  }

  bool isAvailable(RewardedAdPurpose purpose) => _slots[purpose]!.hasAd;

  /// Candidate unit IDs for [purpose], in preference order.
  List<String> _unitsFor(RewardedAdPurpose purpose) {
    switch (purpose) {
      case RewardedAdPurpose.download:
        return AdHelper.downloadRewardAdUnitIds;
      case RewardedAdPurpose.standard:
        return AdHelper.standardRewardAdUnitIds;
    }
  }

  /// Attempts each candidate unit once, in order, until something loads.
  Future<void> load([RewardedAdPurpose purpose = RewardedAdPurpose.standard]) {
    if (!AdConsentManager.canRequestAds) return Future.value();

    final slot = _slots[purpose]!;
    if (slot.hasAd) return Future.value();
    if (slot.loadFuture != null) return slot.loadFuture!;

    final units = _unitsFor(purpose);
    if (units.isEmpty) return Future.value();

    final completer = Completer<void>();
    slot.loadFuture = completer.future;

    void finish() {
      slot.loadFuture = null;
      if (!completer.isCompleted) completer.complete();
    }

    // Build the attempt queue: each unit, interstitial format first.
    final attempts = <({String unitId, _Format format})>[];
    for (final unitId in units) {
      for (final format in _Format.values) {
        if (!slot.formatMismatches.contains('$unitId|${format.name}')) {
          attempts.add((unitId: unitId, format: format));
        }
      }
    }

    var index = 0;
    void tryNext() {
      while (index < attempts.length) {
        final attempt = attempts[index++];
        final loaded = _attemptLoad(slot, attempt, () {
          finish();
        }, (errorCode) {
          if (errorCode == _formatMismatchCode) {
            slot.formatMismatches.add('${attempt.unitId}|${attempt.format.name}');
          }
          // Any failure (format mismatch or no fill) hands over to the next
          // candidate instead of giving up on the whole reward flow.
          tryNext();
        });
        if (loaded) return;
      }
      finish();
    }

    tryNext();
    return completer.future;
  }

  /// Starts one load attempt. Returns true when an async load was started, or
  /// false when the combination is known-bad and must be skipped immediately.
  bool _attemptLoad(
    _Slot slot,
    ({String unitId, _Format format}) attempt,
    VoidCallback onLoaded,
    void Function(int errorCode) onFailed,
  ) {
    if (attempt.format == _Format.rewardedInterstitial) {
      RewardedInterstitialAd.load(
        adUnitId: attempt.unitId,
        request: const AdRequest(),
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            slot.interstitialAd = ad;
            onLoaded();
          },
          onAdFailedToLoad: (error) {
            debugPrint(
              'RewardedInterstitialAd ${attempt.unitId} failed: ${error.message}',
            );
            onFailed(error.code);
          },
        ),
      );
      return true;
    }

    RewardedAd.load(
      adUnitId: attempt.unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          slot.rewardedAd = ad;
          onLoaded();
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd ${attempt.unitId} failed: ${error.message}');
          onFailed(error.code);
        },
      ),
    );
    return true;
  }

  /// Shows an ad, loading one first if necessary. Completes with true only when
  /// the user completed enough of the ad to earn the reward.
  Future<bool> showOrLoad([
    RewardedAdPurpose purpose = RewardedAdPurpose.standard,
  ]) async {
    if (!AdConsentManager.canRequestAds) return false;
    if (_isShowing || AppOpenAdManager.pauseAppOpenAd) return false;

    final slot = _slots[purpose]!;
    if (!slot.hasAd) {
      await load(purpose).timeout(const Duration(seconds: 10), onTimeout: () {});
    }

    final interstitialAd = slot.interstitialAd;
    final rewardedAd = slot.rewardedAd;
    if (interstitialAd == null && rewardedAd == null) return false;

    // Take ownership of the loaded ad. It is disposed in the full-screen
    // callbacks below, after it has been shown — never before.
    slot.interstitialAd = null;
    slot.rewardedAd = null;
    _isShowing = true;

    var rewardEarned = false;
    final result = Completer<bool>();

    void onDismissed() {
      _isShowing = false;
      AppOpenAdManager.markFullScreenAdClosed();
      unawaited(load(purpose));
      if (!result.isCompleted) result.complete(rewardEarned);
    }

    void onShowFailed(Object error) {
      debugPrint('Rewarded ad failed to show: $error');
      _isShowing = false;
      AppOpenAdManager.markFullScreenAdClosed();
      unawaited(load(purpose));
      if (!result.isCompleted) result.complete(false);
    }

    void earned(AdWithoutView ad, RewardItem reward) {
      rewardEarned = true;
    }

    if (interstitialAd != null) {
      interstitialAd.fullScreenContentCallback =
          FullScreenContentCallback<RewardedInterstitialAd>(
            onAdShowedFullScreenContent: (ad) {
              AppOpenAdManager.pauseAppOpenAd = true;
            },
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              onDismissed();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              onShowFailed(error);
            },
          );

      unawaited(
        interstitialAd
            .show(onUserEarnedReward: earned)
            .catchError(onShowFailed),
      );
    } else if (rewardedAd != null) {
      rewardedAd.fullScreenContentCallback =
          FullScreenContentCallback<RewardedAd>(
            onAdShowedFullScreenContent: (ad) {
              AppOpenAdManager.pauseAppOpenAd = true;
            },
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              onDismissed();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              onShowFailed(error);
            },
          );

      unawaited(
        rewardedAd.show(onUserEarnedReward: earned).catchError(onShowFailed),
      );
    }

    return result.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () {
        _isShowing = false;
        return rewardEarned;
      },
    );
  }
}
