import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thiruvasagampro/services/app_update_service.dart';

/// Tests for the network + throttle side of the update check.
///
/// The headline case is a regression: `checkForUpdate` used to record
/// "last checked" only *after* a successful fetch, so a 404 or an offline
/// device fired a fresh request on every single app resume. Measured on a real
/// device before the fix: 3 requests over 3 resumes.
void main() {
  const installedVersion = '1.8.0';
  const installedBuild = '8';

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    PackageInfo.setMockInitialValues(
      appName: 'Thiruvasagam Pro',
      packageName: 'com.dftacademy.thiruvasagampro',
      version: installedVersion,
      buildNumber: installedBuild,
      buildSignature: '',
    );
  });

  /// Builds a service backed by a client that counts its requests.
  ({AppUpdateService service, int Function() calls}) buildService({
    String body = '{"latestVersion":"1.9.0"}',
    int status = 200,
  }) {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return http.Response(
        body,
        status,
        // charset matters: without it http falls back to latin1 and Tamil
        // copy would fail to encode.
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    return (
      service: AppUpdateService.forTesting(client: client),
      calls: () => calls,
    );
  }

  test('prompts when the manifest advertises a newer version', () async {
    final harness = buildService();

    final update = await harness.service.checkForUpdate();

    expect(update, isNotNull);
    expect(update!.latestVersion, '1.9.0');
    expect(update.currentVersion, installedVersion);
    expect(update.currentBuildNumber, installedBuild);
    expect(update.forceUpdate, isFalse);
    expect(harness.calls(), 1);
  });

  test('records the attempt when the fetch fails, so resumes are throttled',
      () async {
    final harness = buildService(status: 404, body: 'not found');

    expect(await harness.service.checkForUpdate(), isNull);
    expect(harness.calls(), 1, reason: 'the first check should reach the network');

    // The lifecycle resume hook calls this again straight away.
    expect(await harness.service.checkForUpdate(), isNull);
    expect(await harness.service.checkForUpdate(), isNull);

    expect(
      harness.calls(),
      1,
      reason: 'a failed check must still open the throttle window',
    );
  });

  test('ignoreThrottle bypasses the throttle for a manual check', () async {
    final harness = buildService(status: 404, body: '');

    await harness.service.checkForUpdate();
    expect(harness.calls(), 1);

    await harness.service.checkForUpdate(ignoreThrottle: true);
    expect(harness.calls(), 2, reason: 'a manual check must not be throttled');
  });

  test('a malformed manifest is treated like a failure, not a crash', () async {
    final harness = buildService(body: 'this is not json');

    expect(await harness.service.checkForUpdate(), isNull);
    expect(harness.calls(), 1);
  });

  test('a manifest with no latestVersion never prompts', () async {
    final harness = buildService(body: '{"forceUpdate":true}');

    expect(await harness.service.checkForUpdate(), isNull);
  });

  test('stays quiet when the installed build is already current', () async {
    final harness = buildService(body: '{"latestVersion":"1.8.0"}');

    expect(await harness.service.checkForUpdate(), isNull);
  });

  test('carries forceUpdate through to the dialog', () async {
    final harness = buildService(
      body: '{"latestVersion":"1.9.0","forceUpdate":true}',
    );

    final update = await harness.service.checkForUpdate();

    expect(update, isNotNull);
    expect(update!.forceUpdate, isTrue);
  });

  test('decodes Tamil copy from the manifest as UTF-8', () async {
    final harness = buildService(
      body: jsonEncode({
        'latestVersion': '1.9.0',
        'title': 'புதிய பதிப்பு கிடைக்கிறது!',
        'releaseNotes': ['புதிய ஒலி வாசிப்பு அம்சம்'],
      }),
    );

    final update = await harness.service.checkForUpdate();

    expect(update, isNotNull);
    expect(update!.title, 'புதிய பதிப்பு கிடைக்கிறது!');
    expect(update.releaseNotes, ['புதிய ஒலி வாசிப்பு அம்சம்']);
  });

  test('a snoozed version is not offered again', () async {
    final harness = buildService();

    await harness.service.snooze('1.9.0');

    expect(await harness.service.checkForUpdate(), isNull);
  });

  test('a newer version than the snoozed one is still offered', () async {
    final harness = buildService();

    await harness.service.snooze('1.9.0');

    // The manifest moved on since the user tapped "Later".
    final movedOn = buildService(body: '{"latestVersion":"2.0.0"}');
    final update = await movedOn.service.checkForUpdate();

    expect(update, isNotNull);
    expect(update!.latestVersion, '2.0.0');
  });
}
