import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_update_config.dart';

/// What happened after the user tapped "Update".
enum UpdateLaunchOutcome {
  /// Google Play took over — either its full-screen immediate flow, or a
  /// background download that finishes on its own.
  playUpdateStarted,

  /// Play could not handle it, so the store listing was opened instead.
  storeOpened,

  /// The user backed out of the Play flow.
  cancelled,

  /// Nothing could be launched (no Play Services and no browser).
  failed,
}

/// Checks for a newer release and drives the update flow.
///
/// Design notes:
/// * **Never throws.** Every failure (offline, DNS, 404, malformed JSON, a
///   plugin missing on the device) collapses to "no update". A version check
///   must never be able to break app start-up.
/// * **Never nags.** A successful check is throttled, and "Later" snoozes the
///   specific version so the user is only asked again when something newer
///   ships.
/// * **Never blocks.** Callers fire this after the first frame.
class AppUpdateService {
  AppUpdateService._({http.Client? client}) : _client = client ?? http.Client();

  static final AppUpdateService instance = AppUpdateService._();

  /// An isolated instance with a stubbed HTTP client, for tests.
  @visibleForTesting
  static AppUpdateService forTesting({required http.Client client}) =>
      AppUpdateService._(client: client);

  /// Injectable so the throttle and failure paths can be tested without a
  /// network. Production always uses the shared instance above.
  final http.Client _client;

  /// Build-time override, mainly for testing:
  /// `--dart-define=UPDATE_CONFIG_URL=http://127.0.0.1:8099/version.json`
  static const String _configUrlOverride =
      String.fromEnvironment('UPDATE_CONFIG_URL');

  /// Where the app looks for `version.json`.
  static const String _defaultConfigUrl =
      'https://thiruvasagam.dftacademy.in/version.json';

  static String get configUrl {
    final override = _configUrlOverride.trim();
    return override.isNotEmpty ? override : _defaultConfigUrl;
  }

  /// Opened when Play cannot perform the in-app update.
  static const String playStoreListingUrl =
      'https://play.google.com/store/apps/details?id=com.dftacademy.thiruvasagampro';

  static const Duration _requestTimeout = Duration(seconds: 8);
  static const Duration _snoozeDuration = Duration(days: 3);
  static const Duration _minCheckInterval = Duration(hours: 6);

  static const String _keySnoozedVersion = 'app_update_snoozed_version';
  static const String _keySnoozedUntil = 'app_update_snoozed_until';
  static const String _keyLastChecked = 'app_update_last_checked';

  bool _checkInFlight = false;
  StreamSubscription<InstallStatus>? _flexibleUpdateSubscription;

  /// Returns non-null only when the user should actually be prompted.
  ///
  /// [ignoreThrottle] bypasses both the throttle and the snooze — use it for a
  /// manual "check for updates" action in Settings.
  Future<PendingUpdate?> checkForUpdate({bool ignoreThrottle = false}) async {
    if (_checkInFlight) return null;
    _checkInFlight = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;

      if (!ignoreThrottle) {
        final lastChecked = prefs.getInt(_keyLastChecked) ?? 0;
        if (now - lastChecked < _minCheckInterval.inMilliseconds) return null;
      }

      // Record the attempt *before* the network call. A failed check is still a
      // check: recording it only on success meant an offline device, or a
      // manifest that 404s, fired a fresh request on every single app resume.
      await prefs.setInt(_keyLastChecked, now);

      final packageInfo = await PackageInfo.fromPlatform();
      final config = await _fetchConfig();
      if (config == null) return null;

      final currentVersion = packageInfo.version;
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
      if (!config.isUpdateAvailable(currentVersion, currentBuild)) return null;

      final force = config.forcesUpdateFor(currentVersion);

      if (!force && !ignoreThrottle) {
        final snoozedVersion = prefs.getString(_keySnoozedVersion);
        final snoozedUntil = prefs.getInt(_keySnoozedUntil) ?? 0;
        if (snoozedVersion == config.latestVersion && now < snoozedUntil) {
          return null;
        }
      }

      return PendingUpdate(
        currentVersion: currentVersion,
        currentBuildNumber: packageInfo.buildNumber,
        config: config,
        forceUpdate: force,
      );
    } catch (error, stackTrace) {
      debugPrint('AppUpdateService: check failed → $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    } finally {
      _checkInFlight = false;
    }
  }

  Future<AppUpdateConfig?> _fetchConfig() async {
    try {
      final response = await _client
          .get(
            Uri.parse(configUrl),
            headers: const {'Cache-Control': 'no-cache'},
          )
          .timeout(_requestTimeout);

      if (response.statusCode != 200) {
        debugPrint('AppUpdateService: HTTP ${response.statusCode} from $configUrl');
        return null;
      }
      return AppUpdateConfig.tryParse(json.decode(response.body));
    } catch (error) {
      debugPrint('AppUpdateService: fetch failed → $error');
      return null;
    }
  }

  /// Remembers that the user chose "Later" for [version].
  Future<void> snooze(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySnoozedVersion, version);
      await prefs.setInt(
        _keySnoozedUntil,
        DateTime.now().add(_snoozeDuration).millisecondsSinceEpoch,
      );
    } catch (error) {
      debugPrint('AppUpdateService: could not save snooze → $error');
    }
  }

  /// Runs the update, preferring Google Play's in-app flow.
  ///
  /// Play is the better path because it installs without leaving the app and
  /// without a download prompt. It is unavailable on sideloaded builds and on
  /// devices without Play Services, so the store listing is the safety net.
  Future<UpdateLaunchOutcome> launchUpdate(PendingUpdate info) async {
    if (!kIsWeb && Platform.isAndroid) {
      final outcome = await _tryPlayInAppUpdate(info);
      if (outcome != null) return outcome;
    }
    return _openStoreListing(info);
  }

  /// Returns `null` when Play cannot do it and the caller should fall back.
  Future<UpdateLaunchOutcome?> _tryPlayInAppUpdate(PendingUpdate info) async {
    try {
      final playInfo = await InAppUpdate.checkForUpdate();
      if (playInfo.updateAvailability != UpdateAvailability.updateAvailable) {
        debugPrint(
          'AppUpdateService: Play has no update yet '
          '(${playInfo.updateAvailability}) → using the store link.',
        );
        return null;
      }

      if (info.forceUpdate) {
        final result = await InAppUpdate.performImmediateUpdate();
        if (result == AppUpdateResult.userDeniedUpdate) {
          return UpdateLaunchOutcome.cancelled;
        }
        if (result == AppUpdateResult.success) {
          return UpdateLaunchOutcome.playUpdateStarted;
        }
        return null; // inAppUpdateFailed → fall back to the store
      }

      final result = await InAppUpdate.startFlexibleUpdate();
      if (result == AppUpdateResult.success) {
        _watchFlexibleDownload();
        return UpdateLaunchOutcome.playUpdateStarted;
      }
      return result == AppUpdateResult.userDeniedUpdate
          ? UpdateLaunchOutcome.cancelled
          : null;
    } on PlatformException catch (error) {
      // Sideloaded builds and devices without Play Services land here.
      debugPrint('AppUpdateService: in-app update unavailable → ${error.code}');
      return null;
    } catch (error) {
      debugPrint('AppUpdateService: in-app update failed → $error');
      return null;
    }
  }

  /// Play downloads a flexible update in the background. Installing is a
  /// separate step, and it is only valid once the download completes.
  void _watchFlexibleDownload() {
    _flexibleUpdateSubscription?.cancel();
    _flexibleUpdateSubscription =
        InAppUpdate.installUpdateListener.listen((status) async {
      if (status != InstallStatus.downloaded) return;
      await _flexibleUpdateSubscription?.cancel();
      _flexibleUpdateSubscription = null;
      try {
        await InAppUpdate.completeFlexibleUpdate();
      } catch (error) {
        debugPrint('AppUpdateService: could not install update → $error');
      }
    }, onError: (Object error) {
      debugPrint('AppUpdateService: install listener error → $error');
    });
  }

  Future<UpdateLaunchOutcome> _openStoreListing(PendingUpdate info) async {
    final target = info.updateUrl ?? playStoreListingUrl;
    try {
      final launched = await launchUrl(
        Uri.parse(target),
        mode: LaunchMode.externalApplication,
      );
      return launched
          ? UpdateLaunchOutcome.storeOpened
          : UpdateLaunchOutcome.failed;
    } catch (error) {
      debugPrint('AppUpdateService: could not open $target → $error');
      return UpdateLaunchOutcome.failed;
    }
  }
}
