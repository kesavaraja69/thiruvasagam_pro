import 'package:flutter_test/flutter_test.dart';
import 'package:thiruvasagampro/models/app_update_config.dart';
import 'package:thiruvasagampro/utils/version_utils.dart';

/// Unit tests for the version check.
///
/// These cover the part of the update flow that decides whether a user is
/// prompted at all. That decision used to live inside the service as private
/// methods, where a mistake would silently either nag every user on every
/// launch or never prompt anyone — neither of which shows up as a crash.
void main() {
  group('VersionUtils.compare', () {
    test('treats missing segments as zero', () {
      expect(VersionUtils.compare('1.9', '1.9.0'), 0);
      expect(VersionUtils.compare('2', '2.0.0'), 0);
    });

    test('compares numerically, not lexicographically', () {
      // The bug this guards: '1.10.0' < '1.9.0' as strings.
      expect(VersionUtils.isNewer('1.10.0', '1.9.0'), isTrue);
      expect(VersionUtils.compare('1.9.0', '1.10.0'), -1);
    });

    test('orders major, then minor, then patch', () {
      expect(VersionUtils.compare('2.0.0', '1.99.99'), 1);
      expect(VersionUtils.compare('1.8.1', '1.8.0'), 1);
      expect(VersionUtils.compare('1.8.0', '1.8.1'), -1);
      expect(VersionUtils.compare('1.8.0', '1.8.0'), 0);
    });

    test('ignores build metadata after +', () {
      expect(VersionUtils.compare('1.8.0+12', '1.8.0+8'), 0);
    });

    test('tolerates a v prefix and a pre-release suffix', () {
      expect(VersionUtils.compare('v1.9.0', '1.8.0'), 1);
      expect(VersionUtils.compare('1.9.0-beta', '1.9.0'), 0);
    });

    test('survives junk without throwing', () {
      expect(VersionUtils.compare('', '1.0.0'), -1);
      expect(VersionUtils.compare('abc', '1.0.0'), -1);
    });
  });

  group('AppUpdateConfig.tryParse', () {
    test('accepts a minimal manifest and defaults the rest', () {
      final config = AppUpdateConfig.tryParse({'latestVersion': '1.9.0'});

      expect(config, isNotNull);
      expect(config!.latestVersion, '1.9.0');
      expect(config.latestBuildNumber, isNull);
      expect(config.minSupportedVersion, isNull);
      expect(config.forceUpdate, isFalse);
      expect(config.releaseNotes, isEmpty);
      expect(config.title, isNull);
      expect(config.updateUrl, isNull);
    });

    test('rejects anything without a usable latestVersion', () {
      expect(AppUpdateConfig.tryParse(null), isNull);
      expect(AppUpdateConfig.tryParse('not a map'), isNull);
      expect(AppUpdateConfig.tryParse(<String, dynamic>{}), isNull);
      expect(AppUpdateConfig.tryParse({'latestVersion': ''}), isNull);
      expect(AppUpdateConfig.tryParse({'latestVersion': '   '}), isNull);
      expect(AppUpdateConfig.tryParse({'latestVersion': 19}), isNull);
    });

    test('reads the full manifest and coerces loose types', () {
      final config = AppUpdateConfig.tryParse({
        'latestVersion': ' 1.9.0 ',
        'latestBuildNumber': '9', // string form must be coerced
        'minSupportedVersion': '1.8.0',
        'forceUpdate': true,
        'title': '  புதிய பதிப்பு  ',
        'message': 'msg',
        'releaseNotes': ['a', '', '   ', '  b  ', 5],
        'updateUrl': 'https://example.com',
      });

      expect(config, isNotNull);
      expect(config!.latestVersion, '1.9.0');
      expect(config.latestBuildNumber, 9);
      expect(config.minSupportedVersion, '1.8.0');
      expect(config.forceUpdate, isTrue);
      expect(config.title, 'புதிய பதிப்பு');
      expect(config.message, 'msg');
      expect(config.releaseNotes, ['a', 'b']);
      expect(config.updateUrl, 'https://example.com');
    });

    test('forceUpdate is only true for a real boolean true', () {
      expect(
        AppUpdateConfig.tryParse({
          'latestVersion': '1.9.0',
          'forceUpdate': 'true',
        })!.forceUpdate,
        isFalse,
      );
    });
  });

  group('isUpdateAvailable', () {
    AppUpdateConfig config({
      String latest = '1.9.0',
      int? build,
      bool force = false,
      String? min,
    }) => AppUpdateConfig(
      latestVersion: latest,
      latestBuildNumber: build,
      forceUpdate: force,
      minSupportedVersion: min,
    );

    test('prompts when the manifest is ahead', () {
      expect(config().isUpdateAvailable('1.8.0', 8), isTrue);
    });

    test('stays quiet when the installed build is current or ahead', () {
      expect(config(latest: '1.8.0').isUpdateAvailable('1.8.0', 8), isFalse);
      expect(config(latest: '1.7.0').isUpdateAvailable('1.8.0', 8), isFalse);
    });

    test('uses the build number to break a version tie', () {
      expect(
        config(latest: '1.8.0', build: 9).isUpdateAvailable('1.8.0', 8),
        isTrue,
      );
      expect(
        config(latest: '1.8.0', build: 8).isUpdateAvailable('1.8.0', 8),
        isFalse,
      );
      expect(
        config(latest: '1.8.0', build: 7).isUpdateAvailable('1.8.0', 8),
        isFalse,
      );
    });

    test('a tie with no build number stays quiet', () {
      expect(config(latest: '1.8.0').isUpdateAvailable('1.8.0', 8), isFalse);
    });
  });

  group('forcesUpdateFor', () {
    test('honours the explicit forceUpdate flag', () {
      final forced = AppUpdateConfig(
        latestVersion: '1.9.0',
        forceUpdate: true,
      );
      expect(forced.forcesUpdateFor('1.8.0'), isTrue);
    });

    test('forces anyone below minSupportedVersion', () {
      final config = AppUpdateConfig(
        latestVersion: '1.9.0',
        minSupportedVersion: '1.8.0',
      );
      expect(config.forcesUpdateFor('1.7.0'), isTrue);
      // Exactly on the floor is still supported.
      expect(config.forcesUpdateFor('1.8.0'), isFalse);
      expect(config.forcesUpdateFor('1.8.5'), isFalse);
    });

    test('does not force when neither rule applies', () {
      expect(
        AppUpdateConfig(latestVersion: '1.9.0').forcesUpdateFor('1.8.0'),
        isFalse,
      );
    });
  });
}
