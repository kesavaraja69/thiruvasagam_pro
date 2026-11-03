import 'package:flutter/material.dart';
import 'package:thiruvasagampro/services/notification_service.dart';
import 'package:thiruvasagampro/services/reading_progress_service.dart';
import 'package:thiruvasagampro/view/screens/reading_screen.dart';

/// Root navigator key, so code that lives outside the widget tree (such as the
/// notification tap handler) can push screens.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Opens the reading screen on the next song that hasn't been read yet.
Future<void> openNextUnreadSong() async {
  final navigator = appNavigatorKey.currentState;
  if (navigator == null) return;

  final chapterId = await ReadingProgressService.nextUnreadChapterId();
  if (chapterId == null) return;

  navigator.push(
    MaterialPageRoute(builder: (_) => ReadingScreen(chapterId: chapterId)),
  );
}

/// Handles a reminder tap that started the app from a cold start.
///
/// The tap can't navigate right away because the splash screen replaces the
/// current route afterwards, which would discard the pushed screen. Instead we
/// wait until the app has settled on the home screen.
Future<void> handlePendingReminderTap() async {
  if (!NotificationService.instance.consumePendingDailyReminderTap()) return;
  await openNextUnreadSong();
}
