import 'dart:io';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-7097654589006373/5177792757'; // Android Test Banner
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // iOS Test Banner
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-7097654589006373/6846097641'; // Android Test Interstitial
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // iOS Test Interstitial
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get appOpenAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-7097654589006373/9032973364';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/5575463023';
    throw UnsupportedError('Unsupported platform');
  }

  static String get rewardedInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-7097654589006373/2715280948'; // Android Test ID
    } else if (Platform.isIOS) {
      // 🚨 Corrected iOS Test ID
      return 'ca-app-pub-3940256099942544/6978759866';
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get openAd {
    if (Platform.isAndroid) {
      // 🚨 Correct Android App Open Test ID
      return 'ca-app-pub-7097654589006373/9032973364';
    } else if (Platform.isIOS) {
      // 🚨 Correct iOS App Open Test ID
      return 'ca-app-pub-3940256099942544/5575463023';
    }
    throw UnsupportedError('Unsupported platform');
  }
}
