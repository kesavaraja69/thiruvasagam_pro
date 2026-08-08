// // // lib/utils/ad_consent_manager.dart

// // import 'package:flutter/material.dart';
// // import 'package:google_mobile_ads/google_mobile_ads.dart';

// // class AdConsentManager {
// //   static Future<void> initializeConsent() async {
// //     // 1. Request the latest consent information from Google
// //     final params = ConsentRequestParameters();

// //     ConsentInformation.instance.requestConsentInfoUpdate(
// //       params,
// //       () async {
// //         // 2. Check if the user is in Europe and needs to see the form
// //         if (await ConsentInformation.instance.isConsentFormAvailable()) {
// //           _loadConsentForm();
// //         } else {
// //           // User is not in Europe, initialize AdMob immediately
// //           _initializeAds();
// //         }
// //       },
// //       (FormError error) {
// //         // If there is a network error, just initialize ads anyway
// //         debugPrint('Consent Error: ${error.message}');
// //         _initializeAds();
// //       },
// //     );
// //   }

// //   static void _loadConsentForm() {
// //     ConsentForm.loadConsentForm(
// //       (ConsentForm consentForm) async {
// //         final status = await ConsentInformation.instance.getConsentStatus();
// //         if (status == ConsentStatus.required) {
// //           // Show the popup to the user
// //           consentForm.show((FormError? formError) {
// //             // Once they click a button (accept/decline), initialize ads
// //             _initializeAds();
// //           });
// //         } else {
// //           // They already gave consent previously
// //           _initializeAds();
// //         }
// //       },
// //       (FormError formError) {
// //         _initializeAds();
// //       },
// //     );
// //   }

// //   static void _initializeAds() {
// //     MobileAds.instance.initialize();
// //   }
// // }

// // lib/utils/ad_consent_manager.dart

// import 'package:flutter/foundation.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';

// class AdConsentManager {
//   static Future<void> initializeConsent() async {
//     final params = ConsentRequestParameters();

//     ConsentInformation.instance.requestConsentInfoUpdate(
//       params,
//       () async {
//         // Check if consent form is available
//         if (await ConsentInformation.instance.isConsentFormAvailable()) {
//           _loadConsentForm();
//         } else {
//           // No consent form needed
//           _initializeAds();
//         }
//       },
//       (FormError error) {
//         debugPrint('Consent Error: ${error.message}');

//         // Initialize ads anyway on error
//         _initializeAds();
//       },
//     );
//   }

//   static void _loadConsentForm() {
//     ConsentForm.loadConsentForm(
//       (ConsentForm consentForm) async {
//         final status = await ConsentInformation.instance.getConsentStatus();

//         if (status == ConsentStatus.required) {
//           // Show consent popup
//           consentForm.show((FormError? formError) async {
//             if (formError != null) {
//               debugPrint('Consent Form Error: ${formError.message}');
//             }

//             // Check if ads can be requested
//             if (await ConsentInformation.instance.canRequestAds()) {
//               _initializeAds();
//             }
//           });
//         } else {
//           // Consent already obtained
//           if (await ConsentInformation.instance.canRequestAds()) {
//             _initializeAds();
//           }
//         }
//       },
//       (FormError formError) {
//         debugPrint('Load Consent Form Error: ${formError.message}');

//         _initializeAds();
//       },
//     );
//   }

//   static Future<void> _initializeAds() async {
//     await MobileAds.instance.initialize();

//     debugPrint('Mobile Ads Initialized');
//   }
// }

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdConsentManager {
  // 🚨 Add an optional callback function here
  static Future<void> initializeConsent({
    Function()? onInitializationComplete,
  }) async {
    final params = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          _loadConsentForm(onInitializationComplete);
        } else {
          _initializeAds(onInitializationComplete);
        }
      },
      (FormError error) {
        debugPrint('Consent Error: ${error.message}');
        _initializeAds(onInitializationComplete);
      },
    );
  }

  static void _loadConsentForm(Function()? onInitializationComplete) {
    ConsentForm.loadConsentForm(
      (ConsentForm consentForm) async {
        final status = await ConsentInformation.instance.getConsentStatus();
        if (status == ConsentStatus.required) {
          consentForm.show((FormError? formError) {
            _initializeAds(onInitializationComplete);
          });
        } else {
          _initializeAds(onInitializationComplete);
        }
      },
      (FormError formError) {
        _initializeAds(onInitializationComplete);
      },
    );
  }

  // 🚨 Trigger the callback after initialization finishes!
  static void _initializeAds(Function()? onInitializationComplete) {
    MobileAds.instance.initialize().then((_) {
      if (onInitializationComplete != null) {
        onInitializationComplete();
      }
    });
  }
}
