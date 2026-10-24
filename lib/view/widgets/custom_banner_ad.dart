import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../services/reward_unlock_service.dart';
import '../../utils/ad_consent_manager.dart';
import '../../utils/ad_helper.dart';
import '../../utils/app_open_ad_manager.dart';

class CustomBannerAd extends StatefulWidget {
  /// Optional second banner unit. When null, the main banner unit is used.
  final String? adUnitId;

  const CustomBannerAd({super.key, this.adUnitId});

  @override
  State<CustomBannerAd> createState() => _CustomBannerAdState();
}

class _CustomBannerAdState extends State<CustomBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;
  bool _failed = false;
  bool _registeredVisible = false;
  bool _adFree = false;

  @override
  void initState() {
    super.initState();

    _adFree = RewardUnlockService.instance.isAdFree;
    RewardUnlockService.instance.addListener(_onRewardStateChanged);
    AdConsentManager.state.addListener(_onConsentChanged);
    if (_adFree) return;

    switch (AdConsentManager.state.value) {
      case AdConsentState.allowed:
        _loadAd();
      case AdConsentState.denied:
        _failed = true;
      case AdConsentState.pending:
        _isLoading = true;
    }
  }

  void _onRewardStateChanged() {
    if (!mounted) return;

    final adFree = RewardUnlockService.instance.isAdFree;
    if (adFree == _adFree) return;
    _adFree = adFree;

    if (adFree) {
      _bannerAd?.dispose();
      _bannerAd = null;
      if (_registeredVisible) {
        _registeredVisible = false;
        AppOpenAdManager.bannerHidden();
      }
      setState(() {
        _isLoaded = false;
        _isLoading = false;
        _failed = false;
      });
    } else {
      setState(_loadAd);
    }
  }

  void _onConsentChanged() {
    if (!mounted) return;

    if (AdConsentManager.state.value == AdConsentState.allowed) {
      if (!_adFree && !_isLoaded && !_isLoading) {
        setState(_loadAd);
      }
      return;
    }

    if (AdConsentManager.state.value == AdConsentState.denied) {
      _bannerAd?.dispose();
      _bannerAd = null;
      if (_registeredVisible) {
        _registeredVisible = false;
        AppOpenAdManager.bannerHidden();
      }
      setState(() {
        _isLoaded = false;
        _isLoading = false;
        _failed = true;
      });
    }
  }

  void _loadAd() {
    if (_isLoaded || RewardUnlockService.instance.isAdFree) return;
    if (!AdConsentManager.canRequestAds) {
      _isLoading = false;
      _failed = true;
      return;
    }

    _isLoading = true;
    _failed = false;

    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId ?? AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || RewardUnlockService.instance.isAdFree) {
            ad.dispose();
            return;
          }
          setState(() {
            _isLoaded = true;
            _isLoading = false;
          });
          if (!_registeredVisible) {
            _registeredVisible = true;
            AppOpenAdManager.bannerShown();
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _isLoaded = false;
            _isLoading = false;
            _failed = true;
          });
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    RewardUnlockService.instance.removeListener(_onRewardStateChanged);
    AdConsentManager.state.removeListener(_onConsentChanged);
    if (_registeredVisible) AppOpenAdManager.bannerHidden();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_adFree || _failed || (!_isLoading && !_isLoaded)) {
      return const SizedBox.shrink();
    }

    // Reserve the banner's height while it loads so the screen does not shift
    // under the user's finger (a common cause of accidental clicks).
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: AdSize.banner.height.toDouble(),
        child: _isLoaded && _bannerAd != null
            ? Center(
                child: SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              )
            : null,
      ),
    );
  }
}
