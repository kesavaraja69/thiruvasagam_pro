import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../services/reward_unlock_service.dart';
import '../../utils/ad_consent_manager.dart';
import '../../utils/ad_helper.dart';
import '../../utils/app_open_ad_manager.dart';

/// A policy-safe 320x50 banner, centered in the available content width.
///
/// The fixed small height keeps every banner slot compact on phones and
/// tablets; wider layouts simply show the banner centered.
class CustomBannerAd extends StatefulWidget {
  /// Optional second banner unit. When null, the main banner unit is used.
  final String? adUnitId;

  const CustomBannerAd({super.key, this.adUnitId});

  @override
  State<CustomBannerAd> createState() => _CustomBannerAdState();
}

class _CustomBannerAdState extends State<CustomBannerAd>
    with WidgetsBindingObserver {
  static const int _minBannerWidth = 320;

  /// Google no-fill is often temporary (network hiccup, freshly created ad
  /// unit, housekeeping). Retry a few times with a growing delay so a banner
  /// that failed once does not stay invisible for the whole session.
  static const List<Duration> _retryDelays = [
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 45),
  ];

  BannerAd? _bannerAd;
  AdSize? _requestedSize;
  bool _isLoaded = false;
  bool _isLoading = false;
  bool _failed = false;
  bool _registeredVisible = false;
  bool _adFree = false;
  int _retryCount = 0;
  Timer? _retryTimer;

  /// Width handed to us by the last LayoutBuilder pass.
  double _availableWidth = 0;

  /// Guards against scheduling more than one load for the same width.
  double? _scheduledWidth;

  /// Invalidates late callbacks after a resize or disposal.
  int _loadToken = 0;

  double get _reservedHeight =>
      _requestedSize?.height.toDouble() ?? AdSize.banner.height.toDouble();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _adFree = RewardUnlockService.instance.isAdFree;
    RewardUnlockService.instance.addListener(_onRewardStateChanged);
    AdConsentManager.state.addListener(_onConsentChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;

    // Many "disappearing banner" reports are just a no-fill while the app was
    // in the background. Retry with a fresh budget when the user comes back.
    _retryCount = 0;
    if (!_adFree &&
        !_isLoaded &&
        !_isLoading &&
        AdConsentManager.state.value == AdConsentState.allowed) {
      _reloadForCurrentWidth();
    }
  }

  void _scheduleLoadForWidth(double width) {
    if (width < _minBannerWidth) return;
    if (_scheduledWidth == width) return;
    _scheduledWidth = width;
    _retryCount = 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _scheduledWidth != width) return;
      _reload(width);
    });
  }

  /// Schedules a capped retry after a failed load. Temporary no-fill is
  /// common, so hiding the banner forever on the first failure makes the ad
  /// look like it "disappeared".
  void _scheduleRetry() {
    _retryTimer?.cancel();
    if (!mounted || _adFree) return;
    if (AdConsentManager.state.value == AdConsentState.denied) return;
    if (_retryCount >= _retryDelays.length) return;

    final delay = _retryDelays[_retryCount];
    _retryCount++;

    _retryTimer = Timer(delay, () {
      if (!mounted || _adFree || _isLoaded || _isLoading) return;
      if (_availableWidth < _minBannerWidth) return;
      if (AdConsentManager.state.value == AdConsentState.pending) {
        _scheduleRetry();
        return;
      }
      if (!AdConsentManager.canRequestAds) return;
      _reload(_availableWidth);
    });
  }

  Future<void> _reload(double width) async {
    if (!mounted || _adFree) return;

    _retryTimer?.cancel();
    _loadToken++;
    _isLoading = false;
    _isLoaded = false;
    _failed = false;

    final previous = _bannerAd;
    _bannerAd = null;
    if (_registeredVisible) {
      _registeredVisible = false;
      AppOpenAdManager.bannerHidden();
    }
    previous?.dispose();
    setState(() {});

    if (AdConsentManager.state.value == AdConsentState.pending) {
      // Wait for the consent result; _onConsentChanged will retry.
      return;
    }
    if (!AdConsentManager.canRequestAds) {
      setState(() => _failed = true);
      return;
    }

    await _loadAd();
  }

  Future<void> _loadAd() async {
    if (!mounted || _isLoading || _isLoaded || _adFree) return;
    if (!AdConsentManager.canRequestAds) return;

    final token = ++_loadToken;

    _isLoading = true;
    _failed = false;

    const AdSize size = AdSize.banner;

    if (!mounted || token != _loadToken) return;

    String adUnitId;
    try {
      adUnitId = widget.adUnitId ?? AdHelper.bannerAdUnitId;
    } catch (error) {
      debugPrint('No banner unit available: $error');
      setState(() {
        _isLoading = false;
        _failed = true;
      });
      return;
    }

    setState(() => _requestedSize = size);

    final banner = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted ||
              token != _loadToken ||
              RewardUnlockService.instance.isAdFree) {
            ad.dispose();
            return;
          }
          final loadedBanner = ad as BannerAd;
          _retryTimer?.cancel();
          _retryCount = 0;
          setState(() {
            _bannerAd = loadedBanner;
            _isLoaded = true;
            _isLoading = false;
            _requestedSize = loadedBanner.size;
          });
          if (!_registeredVisible) {
            _registeredVisible = true;
            AppOpenAdManager.bannerShown();
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          ad.dispose();
          if (!mounted || token != _loadToken) return;
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
            _isLoading = false;
            _failed = true;
          });
          _scheduleRetry();
        },
      ),
    );

    _bannerAd = banner;
    await banner.load();
  }

  void _disposeBanner() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _loadToken++;
    _bannerAd?.dispose();
    _bannerAd = null;
    if (_registeredVisible) {
      _registeredVisible = false;
      AppOpenAdManager.bannerHidden();
    }
  }

  void _onRewardStateChanged() {
    if (!mounted) return;

    final adFree = RewardUnlockService.instance.isAdFree;
    if (adFree == _adFree) return;
    _adFree = adFree;

    if (adFree) {
      _disposeBanner();
      setState(() {
        _isLoaded = false;
        _isLoading = false;
        _failed = false;
      });
    } else if (_availableWidth >= _minBannerWidth) {
      _reloadForCurrentWidth();
    }
  }

  void _onConsentChanged() {
    if (!mounted) return;

    if (AdConsentManager.state.value == AdConsentState.allowed) {
      if (!_adFree && !_isLoaded && !_isLoading) {
        _reloadForCurrentWidth();
      }
      return;
    }

    if (AdConsentManager.state.value == AdConsentState.denied) {
      _disposeBanner();
      setState(() {
        _isLoaded = false;
        _isLoading = false;
        _failed = true;
      });
    }
  }

  void _reloadForCurrentWidth() {
    if (_availableWidth >= _minBannerWidth) {
      _retryCount = 0;
      _reload(_availableWidth);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    RewardUnlockService.instance.removeListener(_onRewardStateChanged);
    AdConsentManager.state.removeListener(_onConsentChanged);
    _disposeBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width.isFinite &&
            (_availableWidth - width).abs() >= 24 &&
            width >= _minBannerWidth) {
          _availableWidth = width;
          _scheduleLoadForWidth(width);
        }

        if (_adFree || _failed || width < _minBannerWidth) {
          return const SizedBox.shrink();
        }

        // Reserve the final ad height while loading so the content below does
        // not jump under the user's finger (a common cause of accidental
        // clicks and a poor reading experience).
        return SizedBox(
          width: double.infinity,
          height: _reservedHeight,
          child: _isLoaded && _bannerAd != null
              ? Center(
                  child: SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                )
              : null,
        );
      },
    );
  }
}
