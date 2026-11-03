import '../utils/version_utils.dart';

/// Parsed contents of the remote `version.json` manifest.
///
/// Every field except [latestVersion] is optional, so the smallest usable
/// manifest is just `{"latestVersion": "1.9.0"}`.
class AppUpdateConfig {
  const AppUpdateConfig({
    required this.latestVersion,
    this.latestBuildNumber,
    this.minSupportedVersion,
    this.forceUpdate = false,
    this.title,
    this.message,
    this.releaseNotes = const <String>[],
    this.updateUrl,
  });

  /// Newest published version, e.g. `1.9.0`.
  final String latestVersion;

  /// Optional `versionCode`. Used only to break ties when the version string
  /// is unchanged (e.g. you shipped `1.8.0+9` after `1.8.0+8`).
  final int? latestBuildNumber;

  /// Any install older than this is forced to update. Lets you retire a
  /// broken release without shipping a new one.
  final String? minSupportedVersion;

  /// Force the dialog to be non-dismissible for everyone.
  final bool forceUpdate;

  /// Optional override for the dialog heading.
  final String? title;

  /// Optional override for the dialog body copy.
  final String? message;

  /// Optional "what's new" bullets.
  final List<String> releaseNotes;

  /// Optional override for the destination opened by the update button.
  final String? updateUrl;

  // ─── Decisions ──────────────────────────────────────────────────────
  // Kept here as pure functions rather than inside the service so the rules
  // that decide whether a user sees a dialog can be unit tested directly.

  /// Whether an install at [currentVersion] / [currentBuild] should be offered
  /// this update.
  ///
  /// A higher version string always wins. When the strings are equal, the
  /// optional [latestBuildNumber] breaks the tie — that is how you ship
  /// `1.8.0+9` on top of `1.8.0+8`.
  bool isUpdateAvailable(String currentVersion, int currentBuild) {
    final comparison = VersionUtils.compare(latestVersion, currentVersion);
    if (comparison > 0) return true;
    if (comparison < 0) return false;

    final remoteBuild = latestBuildNumber;
    return remoteBuild != null && remoteBuild > currentBuild;
  }

  /// Whether an install at [currentVersion] is below the supported floor and
  /// therefore must update.
  bool forcesUpdateFor(String currentVersion) {
    if (forceUpdate) return true;
    final minimum = minSupportedVersion;
    return minimum != null && VersionUtils.isNewer(minimum, currentVersion);
  }

  /// Returns `null` when [decoded] is not a usable manifest, so callers can
  /// treat malformed JSON exactly like a network failure.
  static AppUpdateConfig? tryParse(Object? decoded) {
    if (decoded is! Map) return null;

    final latest = decoded['latestVersion'];
    if (latest is! String || latest.trim().isEmpty) return null;

    final rawNotes = decoded['releaseNotes'];
    final notes = <String>[];
    if (rawNotes is List) {
      for (final note in rawNotes) {
        if (note is String && note.trim().isNotEmpty) notes.add(note.trim());
      }
    }

    return AppUpdateConfig(
      latestVersion: latest.trim(),
      latestBuildNumber: _asInt(decoded['latestBuildNumber']),
      minSupportedVersion: _asString(decoded['minSupportedVersion']),
      forceUpdate: decoded['forceUpdate'] == true,
      title: _asString(decoded['title']),
      message: _asString(decoded['message']),
      releaseNotes: notes,
      updateUrl: _asString(decoded['updateUrl']),
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static String? _asString(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }
}

/// A confirmed "a newer version exists" result, ready to hand to the dialog.
class PendingUpdate {
  const PendingUpdate({
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.config,
    required this.forceUpdate,
  });

  /// Version installed on this device, e.g. `1.8.0`.
  final String currentVersion;

  /// `versionCode` installed on this device, e.g. `8`.
  final String currentBuildNumber;

  final AppUpdateConfig config;

  /// True when the update cannot be skipped.
  final bool forceUpdate;

  String get latestVersion => config.latestVersion;
  String? get title => config.title;
  String? get message => config.message;
  List<String> get releaseNotes => config.releaseNotes;
  String? get updateUrl => config.updateUrl;
}
