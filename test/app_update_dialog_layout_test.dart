import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thiruvasagampro/models/app_update_config.dart';
import 'package:thiruvasagampro/view/widgets/app_update_dialog.dart';

/// Layout regression tests for the "update available" dialog.
///
/// Two real failures these lock down:
///
/// 1. The shared `Responsive` helpers key typography off screen *width* but
///    vertical spacing off screen *height*. On a landscape phone that inflated
///    text to 1.6x while collapsing spacing to 0.5x, so the pinned footer ate
///    the dialog and the update button ended up off-screen.
/// 2. A tall single-column body pushed the headline below the fold on a short
///    viewport, even though the screen had ~900px of unused width beside it.
void main() {
  const tamilTitle = 'புதிய பதிப்பு கிடைக்கிறது!';
  const updateLabel = 'புதுப்பிக்கவும் (Update)';
  const laterLabel = 'பிறகு (Later)';
  const forceLabel = 'இப்போது புதுப்பிக்கவும்';

  PendingUpdate buildInfo({bool force = false}) => PendingUpdate(
    currentVersion: '1.8.0',
    currentBuildNumber: '8',
    forceUpdate: force,
    config: const AppUpdateConfig(
      latestVersion: '1.9.0',
      latestBuildNumber: 9,
      title: tamilTitle,
      message: 'செயலியின் புதிய பதிப்பு தயாராக உள்ளது.',
      releaseNotes: [
        'புதிய ஒலி வாசிப்பு அம்சம்',
        'பாடல் தேடல் வேகமாக மாறியது',
        'சிறு பிழைகள் திருத்தப்பட்டன',
      ],
    ),
  );

  Future<void> pumpDialog(
    WidgetTester tester,
    Size size, {
    bool force = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final info = buildInfo(force: force);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showAppUpdateDialog(context, info: info),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder updateButton() =>
      find.ancestor(of: find.text(updateLabel), matching: find.byType(ElevatedButton));

  testWidgets('portrait phone stacks the emblem above the copy', (tester) async {
    await pumpDialog(tester, const Size(400, 800));

    expect(tester.takeException(), isNull);

    final emblem = tester.getRect(find.byType(Image));
    final title = tester.getRect(find.text(tamilTitle));
    expect(
      emblem.bottom,
      lessThanOrEqualTo(title.top),
      reason: 'portrait should stack the emblem above the headline',
    );

    expect(updateButton(), findsOneWidget);
    expect(find.text(laterLabel), findsOneWidget);
  });

  testWidgets('landscape phone places the emblem beside the copy', (
    tester,
  ) async {
    await pumpDialog(tester, const Size(904, 407));

    expect(tester.takeException(), isNull);

    final emblem = tester.getRect(find.byType(Image));
    final title = tester.getRect(find.text(tamilTitle));
    expect(
      emblem.right,
      lessThanOrEqualTo(title.left),
      reason:
          'a short viewport should move the emblem beside the headline rather '
          'than pushing it below the fold',
    );
  });

  testWidgets('landscape phone keeps the update action fully on screen', (
    tester,
  ) async {
    const height = 407.0;
    await pumpDialog(tester, const Size(904, height));

    expect(tester.takeException(), isNull);

    final rect = tester.getRect(updateButton());
    expect(
      rect.bottom,
      lessThanOrEqualTo(height),
      reason: 'the pinned footer must never be pushed below the fold',
    );
    expect(rect.top, greaterThanOrEqualTo(0.0));
    expect(find.text(laterLabel), findsOneWidget);
  });

  testWidgets('short phone screen keeps the actions reachable', (tester) async {
    const height = 360.0;
    await pumpDialog(tester, const Size(320, height));

    expect(tester.takeException(), isNull);

    final rect = tester.getRect(updateButton());
    expect(rect.bottom, lessThanOrEqualTo(height));
  });

  testWidgets('tablet lays out without errors', (tester) async {
    await pumpDialog(tester, const Size(1024, 768));

    expect(tester.takeException(), isNull);
    expect(updateButton(), findsOneWidget);
    expect(find.text(laterLabel), findsOneWidget);
  });

  testWidgets('forced update offers no way out', (tester) async {
    await pumpDialog(tester, const Size(400, 800), force: true);

    expect(tester.takeException(), isNull);
    expect(find.text(forceLabel), findsOneWidget);
    expect(find.text(updateLabel), findsNothing);
    expect(find.text(laterLabel), findsNothing);
  });
}
