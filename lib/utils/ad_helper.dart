import 'dart:io';

import 'package:flutter/foundation.dart';

/// Ad unit IDs for the app.
///
/// Debug builds always use Google's official sample ad units so development
/// and testing never generate invalid traffic on the live account.
///
/// Release builds can also opt into the sample units with
/// `--dart-define=USE_TEST_ADS=true`. Use that only for QA/emulator runs of a
/// release build — never for a build uploaded to Google Play.
///
/// Live units that are not configured are returned as `null` instead of
/// silently falling back to Google's sample ads. Shipping sample ads in a
/// production app breaks AdMob policy, so the related feature simply stays
/// hidden until a real unit ID is supplied.
class AdHelper {
  static const bool _useTestAds = bool.fromEnvironment('USE_TEST_ADS');

  /// True when every format should use Google's sample ad units.
  static bool get testAdsEnabled => kDebugMode || _useTestAds;

  // Google's official sample units.
  static const String _androidBannerTest =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _iosBannerTest = 'ca-app-pub-3940256099942544/2934735716';
  static const String _androidInterstitialTest =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _iosInterstitialTest =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _androidRewardedTest =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _iosRewardedTest =
      'ca-app-pub-3940256099942544/1712485313';
  static const String _androidAppOpenTest =
      'ca-app-pub-3940256099942544/9257395921';
  static const String _iosAppOpenTest =
      'ca-app-pub-3940256099942544/5575463023';
  static const String _androidNativeTest =
      'ca-app-pub-3940256099942544/2247696110';
  static const String _iosNativeTest = 'ca-app-pub-3940256099942544/3986624511';

  // Live units. Rewarded and native units are supplied at build time so a
  // release build without them fails closed instead of serving test ads.
  //
  //   --dart-define=REWARDED_AD_UNIT_ID=ca-app-pub-xxxx/yyyy
  //   --dart-define=REWARDED_AD_UNIT_ID_IOS=ca-app-pub-xxxx/yyyy
  //   --dart-define=NATIVE_AD_UNIT_ID_ANDROID=ca-app-pub-xxxx/yyyy
  //   --dart-define=NATIVE_AD_UNIT_ID_IOS=ca-app-pub-xxxx/yyyy
  static const String _releaseRewardedAdUnitId = String.fromEnvironment(
    'REWARDED_AD_UNIT_ID',
  );
  static const String _releaseRewardedAdUnitIdIOS = String.fromEnvironment(
    'REWARDED_AD_UNIT_ID_IOS',
  );
  static const String _releaseNativeAdUnitIdAndroid = String.fromEnvironment(
    'NATIVE_AD_UNIT_ID_ANDROID',
  );
  static const String _releaseNativeAdUnitIdIOS = String.fromEnvironment(
    'NATIVE_AD_UNIT_ID_IOS',
  );

  static String get bannerAdUnitId {
    if (testAdsEnabled) {
      if (Platform.isAndroid) return _androidBannerTest;
      if (Platform.isIOS) return _iosBannerTest;
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-7097654589006373/5177792757';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Second banner unit, used inline on the home screen. Debug builds always
  /// fall back to Google's sample banner so testing cannot generate invalid
  /// traffic on the live unit.
  static String get inlineBannerAdUnitId {
    if (testAdsEnabled) return bannerAdUnitId;
    if (Platform.isAndroid) {
      return 'ca-app-pub-7097654589006373/8508192662';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Third banner unit, used for the extra banner between the lyrics and the
  /// audio player on the reading screen.
  static String get readingBannerAdUnitId {
    if (testAdsEnabled) return bannerAdUnitId;
    if (Platform.isAndroid) {
      return 'ca-app-pub-7097654589006373/2879193517';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get interstitialAdUnitId {
    if (testAdsEnabled) {
      if (Platform.isAndroid) return _androidInterstitialTest;
      if (Platform.isIOS) return _iosInterstitialTest;
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-7097654589006373/6846097641';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    throw UnsupportedError('Unsupported platform');
  }

  static bool get rewardedAdsAvailable => rewardedAdUnitId != null;

  /// `null` when no live rewarded unit was configured for this platform.
  static String? get rewardedAdUnitId {
    if (testAdsEnabled) {
      if (Platform.isAndroid) return _androidRewardedTest;
      if (Platform.isIOS) return _iosRewardedTest;
      return null;
    }
    if (Platform.isAndroid) {
      return _releaseRewardedAdUnitId.isEmpty ? null : _releaseRewardedAdUnitId;
    }
    if (Platform.isIOS) {
      return _releaseRewardedAdUnitIdIOS.isEmpty
          ? null
          : _releaseRewardedAdUnitIdIOS;
    }
    return null;
  }

  /// Native advanced unit used for the inline card in the chapter and
  /// bookmark lists. `null` until a live unit ID is configured.
  static String? get nativeAdUnitId {
    if (testAdsEnabled) {
      if (Platform.isAndroid) return _androidNativeTest;
      if (Platform.isIOS) return _iosNativeTest;
      return null;
    }
    if (Platform.isAndroid) {
      return _releaseNativeAdUnitIdAndroid.isEmpty
          ? null
          : _releaseNativeAdUnitIdAndroid;
    }
    if (Platform.isIOS) {
      return _releaseNativeAdUnitIdIOS.isEmpty
          ? null
          : _releaseNativeAdUnitIdIOS;
    }
    return null;
  }

  static bool get nativeAdsAvailable => nativeAdUnitId != null;

  static String get appOpenAdUnitId {
    if (testAdsEnabled) {
      if (Platform.isAndroid) return _androidAppOpenTest;
      if (Platform.isIOS) return _iosAppOpenTest;
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-7097654589006373/9032973364';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/5575463023';
    }
    throw UnsupportedError('Unsupported platform');
  }
}
