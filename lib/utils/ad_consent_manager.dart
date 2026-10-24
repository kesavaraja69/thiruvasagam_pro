import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Whether ads may be requested. Ads must never be loaded while the state is
/// [pending] or [denied].
enum AdConsentState { pending, allowed, denied }

/// Outcome of opening the Google privacy options form.
enum PrivacyOptionsResult { shown, notRequired, failed }

class AdConsentManager {
  /// Shared state so banners and providers can load only after the UMP flow
  /// finishes. `denied` means the user did not grant consent (or consent could
  /// not be determined), in which case no ads may be requested.
  static final ValueNotifier<AdConsentState> state =
      ValueNotifier<AdConsentState>(AdConsentState.pending);

  static bool get canRequestAds => state.value == AdConsentState.allowed;

  static void initializeConsent({Function()? onInitializationComplete}) {
    final params = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          _loadConsentForm(onInitializationComplete);
        } else {
          await _finishConsent(onInitializationComplete);
        }
      },
      (FormError error) async {
        debugPrint('Consent Error: ${error.message}');
        // The update failed. Only continue if the SDK already has valid
        // consent cached; otherwise no ads are requested.
        await _finishConsent(onInitializationComplete);
      },
    );
  }

  static void _loadConsentForm(Function()? onInitializationComplete) {
    ConsentForm.loadConsentForm(
      (ConsentForm consentForm) async {
        final status = await ConsentInformation.instance.getConsentStatus();
        if (status == ConsentStatus.required) {
          consentForm.show((FormError? formError) async {
            if (formError != null) {
              debugPrint('Consent Form Error: ${formError.message}');
            }
            consentForm.dispose();
            await _finishConsent(onInitializationComplete);
          });
        } else {
          consentForm.dispose();
          await _finishConsent(onInitializationComplete);
        }
      },
      (FormError formError) async {
        debugPrint('Load Consent Form Error: ${formError.message}');
        await _finishConsent(onInitializationComplete);
      },
    );
  }

  static Future<void> _finishConsent(
    Function()? onInitializationComplete,
  ) async {
    if (await refreshConsentState()) {
      onInitializationComplete?.call();
    }
  }

  /// Re-opens the Google privacy options form so users can change or withdraw
  /// consent at any time.
  static Future<PrivacyOptionsResult> showPrivacyOptionsForm() async {
    try {
      final requirement = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      if (requirement != PrivacyOptionsRequirementStatus.required) {
        return PrivacyOptionsResult.notRequired;
      }

      final dismissed = Completer<FormError?>();
      await ConsentForm.showPrivacyOptionsForm((FormError? error) {
        if (!dismissed.isCompleted) dismissed.complete(error);
      });

      final error = await dismissed.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => null,
      );
      if (error != null) {
        debugPrint('Privacy options form error: ${error.message}');
      }

      await refreshConsentState();
      return error == null
          ? PrivacyOptionsResult.shown
          : PrivacyOptionsResult.failed;
    } catch (error) {
      debugPrint('Privacy options form failed: $error');
      return PrivacyOptionsResult.failed;
    }
  }

  /// Re-reads the UMP decision and updates [state]. When consent is withdrawn
  /// the state becomes [AdConsentState.denied], which immediately removes
  /// banners and stops interstitials/app-open/rewarded ads.
  static Future<bool> refreshConsentState() async {
    if (!await ConsentInformation.instance.canRequestAds()) {
      state.value = AdConsentState.denied;
      return false;
    }

    try {
      await MobileAds.instance.initialize();

      // Optional testing hook: `--dart-define=AD_TEST_DEVICE_ID=...` makes the
      // SDK serve test ads on that device, so live units can be exercised
      // without generating invalid traffic. It is empty in production builds.
      const testDeviceId = String.fromEnvironment('AD_TEST_DEVICE_ID');
      if (testDeviceId.isNotEmpty) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: [testDeviceId]),
        );
      }

      state.value = AdConsentState.allowed;
      return true;
    } catch (error) {
      debugPrint('AdMob initialization failed: $error');
      state.value = AdConsentState.denied;
      return false;
    }
  }
}
