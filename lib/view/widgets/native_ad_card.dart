import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../services/reward_unlock_service.dart';
import '../../utils/ad_consent_manager.dart';
import '../../utils/ad_helper.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_open_ad_manager.dart';

/// An inline, clearly-labelled native ad card for content lists.
///
/// Native advanced ads are designed to sit inside a list without breaking the
/// reading flow. The card is only shown when a live native unit is configured
/// (or when running with test ads), so a release build without a native unit
/// simply has no empty gap.
class NativeAdCard extends StatefulWidget {
  /// Optional override; defaults to [AdHelper.nativeAdUnitId].
  final String? adUnitId;

  const NativeAdCard({super.key, this.adUnitId});

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _nativeAd;
  bool _isLoading = false;
  bool _isLoaded = false;
  bool _failed = false;
  bool _adFree = false;
  bool _registeredVisible = false;
  int _loadToken = 0;
  int _retryCount = 0;
  Timer? _retryTimer;

  bool get _platformSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  String? get _adUnitId => widget.adUnitId ?? AdHelper.nativeAdUnitId;

  @override
  void initState() {
    super.initState();
    _adFree = RewardUnlockService.instance.isAdFree;
    RewardUnlockService.instance.addListener(_onRewardStateChanged);
    AdConsentManager.state.addListener(_onConsentChanged);

    if (_platformSupported && !_adFree) {
      switch (AdConsentManager.state.value) {
        case AdConsentState.allowed:
          _loadAd();
        case AdConsentState.pending:
        case AdConsentState.denied:
          break;
      }
    }
  }

  void _onRewardStateChanged() {
    if (!mounted) return;
    final adFree = RewardUnlockService.instance.isAdFree;
    if (adFree == _adFree) return;
    _adFree = adFree;

    if (adFree) {
      _disposeAd();
      setState(() {
        _isLoaded = false;
        _isLoading = false;
        _failed = false;
      });
    } else if (_platformSupported &&
        AdConsentManager.state.value == AdConsentState.allowed) {
      _retryCount = 0;
      _failed = false;
      _loadAd();
    }
  }

  void _onConsentChanged() {
    if (!mounted) return;

    if (AdConsentManager.state.value == AdConsentState.allowed) {
      if (!_adFree && !_isLoaded && !_isLoading) {
        _retryCount = 0;
        _failed = false;
        _loadAd();
      }
      return;
    }
    if (AdConsentManager.state.value == AdConsentState.denied) {
      _disposeAd();
      setState(() {
        _isLoaded = false;
        _isLoading = false;
        _failed = true;
      });
    }
  }

  void _loadAd() {
    if (!mounted || _adFree || _isLoading || _isLoaded || _failed) return;
    if (!_platformSupported || !AdConsentManager.canRequestAds) return;

    final adUnitId = _adUnitId;
    if (adUnitId == null) {
      setState(() => _failed = true);
      return;
    }

    final token = ++_loadToken;
    _isLoading = true;

    final nativeAd = NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (Ad ad) {
          if (!mounted ||
              token != _loadToken ||
              RewardUnlockService.instance.isAdFree) {
            ad.dispose();
            return;
          }
          _retryTimer?.cancel();
          _retryCount = 0;
          setState(() {
            _nativeAd = ad as NativeAd;
            _isLoaded = true;
            _isLoading = false;
            _failed = false;
          });
          if (!_registeredVisible) {
            _registeredVisible = true;
            AppOpenAdManager.bannerShown();
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('NativeAd failed to load: $error');
          ad.dispose();
          if (!mounted || token != _loadToken) return;
          setState(() {
            _nativeAd = null;
            _isLoaded = false;
            _isLoading = false;
            _failed = true;
          });
          _scheduleRetry();
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: AppColors.parchmentBase,
        cornerRadius: 12,
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.vintageInk,
          backgroundColor: AppColors.parchmentBase,
          size: 15,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black87,
          backgroundColor: AppColors.parchmentBase,
          size: 12,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black54,
          backgroundColor: AppColors.parchmentBase,
          size: 11,
        ),
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: AppColors.vintageInk,
          size: 13,
        ),
      ),
    );

    _nativeAd = nativeAd;
    nativeAd.load();
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    if (!mounted || _adFree || _retryCount >= 1) return;
    if (AdConsentManager.state.value == AdConsentState.denied) return;

    _retryCount++;
    _retryTimer = Timer(const Duration(seconds: 20), () {
      if (!mounted || _adFree || _isLoaded || _isLoading) return;
      if (!_platformSupported || !AdConsentManager.canRequestAds) return;
      setState(() => _failed = false);
      _loadAd();
    });
  }

  void _disposeAd() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _loadToken++;
    _nativeAd?.dispose();
    _nativeAd = null;
    if (_registeredVisible) {
      _registeredVisible = false;
      AppOpenAdManager.bannerHidden();
    }
  }

  @override
  void dispose() {
    RewardUnlockService.instance.removeListener(_onRewardStateChanged);
    AdConsentManager.state.removeListener(_onConsentChanged);
    _disposeAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_platformSupported ||
        _adFree ||
        _failed ||
        _adUnitId == null ||
        (!_isLoading && !_isLoaded)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // AdMob's template already paints its own attribution badge; this
          // extra local label keeps the Tamil audience informed as well.
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 2),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.dividerBrown.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'விளம்பரம் · Ad',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dividerBrown,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 350,
            child: _isLoaded && _nativeAd != null
                ? AdWidget(ad: _nativeAd!)
                : null,
          ),
        ],
      ),
    );
  }
}
