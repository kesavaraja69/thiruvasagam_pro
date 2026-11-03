import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thiruvasagampro/view/screens/onboarding_screen.dart';

/// Regression test for the onboarding layout crash:
///
///   "RenderFlex children have non-zero flex but incoming height constraints
///    are unbounded"
///
/// The portrait step used `Spacer()` (which is an `Expanded`) inside a
/// `SingleChildScrollView`. A scroll view hands its child an unbounded height,
/// so no child may claim the remaining space — the two directives are mutually
/// exclusive. On a phone this threw during `performLayout`, breaking the very
/// first screen a new user sees.
void main() {
  Future<void> pumpOnboarding(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    await tester.pump();
  }

  testWidgets('portrait phone lays out without errors', (tester) async {
    await pumpOnboarding(tester, const Size(400, 800));

    expect(tester.takeException(), isNull);
    expect(find.byType(ElevatedButton), findsWidgets);
  });

  testWidgets('short portrait screen scrolls instead of overflowing', (
    tester,
  ) async {
    await pumpOnboarding(tester, const Size(360, 420));

    expect(tester.takeException(), isNull);
    expect(find.byType(ElevatedButton), findsWidgets);
  });

  testWidgets('tablet landscape lays out without errors', (tester) async {
    await pumpOnboarding(tester, const Size(1024, 768));

    expect(tester.takeException(), isNull);
    expect(find.byType(ElevatedButton), findsWidgets);
  });
}
