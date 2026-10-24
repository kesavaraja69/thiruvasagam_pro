import 'dart:io';

import 'package:flutter/foundation.dart';

/// Ad unit IDs for the app.
///
/// Debug builds always use Google's official sample ad units so development
/// and testing never generate invalid traffic on the live account. Release
/// builds use the production units.
class AdHelper {
  /// Live Android rewarded unit can be supplied at build time:
  /// `--dart-define=REWARDED_AD_UNIT_ID=ca-app-pub-xxxx/yyyy`.
  /// The default is Google's sample unit until a live rewarded unit is set.
  static const String _releaseRewardedAdUnitId = String.fromEnvironment(
    'REWARDED_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917',
  );

  static String get bannerAdUnitId {
    if (kDebugMode) {
      if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2934735716';
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
    if (kDebugMode) return bannerAdUnitId;
    if (Platform.isAndroid) {
      return 'ca-app-pub-7097654589006373/8508192662';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) {
      if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-7097654589006373/6846097641';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get rewardedAdUnitId {
    if (kDebugMode) {
      if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/5224354917';
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/1712485313';
    }
    if (Platform.isAndroid) return _releaseRewardedAdUnitId;
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/1712485313';
    throw UnsupportedError('Unsupported platform');
  }

  static String get appOpenAdUnitId {
    if (kDebugMode) {
      if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/9257395921';
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/5575463023';
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-7097654589006373/9032973364';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/5575463023';
    }
    throw UnsupportedError('Unsupported platform');
  }
}
