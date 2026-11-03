import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Handles the daily "read / listen to a song" reminder.
///
/// This is a plain local notification: it is scheduled on the device and
/// needs no server or internet connection. By default it repeats every day
/// at 6:00 PM; the user can change (or switch off) that time in Settings.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  /// Fixed id so re-scheduling always replaces the previous reminder.
  static const int dailyReminderId = 1001;

  /// Payload attached to the daily reminder, used to recognise its tap.
  static const String dailyReminderPayload = 'daily_reminder';

  static const String _channelId = 'daily_reminder';
  static const String _channelName = 'தினசரி நினைவூட்டல்';
  static const String _channelDescription =
      'தினமும் பாடலைப் படிக்க / கேட்க நினைவூட்டும் அறிவிப்பு';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Invoked when the user taps the daily reminder while the app is running.
  /// Set from `main()` so the handler can push the reading screen.
  VoidCallback? onDailyReminderTap;

  /// True when a tap launched the app from a cold start and hasn't been
  /// handled yet (the splash screen is still on top at that point).
  bool _pendingDailyReminderTap = false;

  /// Reminders are only scheduled on the platforms the plugin supports for
  /// scheduling (web/Linux/Windows are skipped so startup never throws).
  bool get _isSupported {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      default:
        return false;
    }
  }

  /// Prepares the notification plugin and timezone database.
  /// Call once, before `runApp`.
  Future<void> initialize() async {
    if (_initialized || !_isSupported) return;

    try {
      tz_data.initializeTimeZones();
      try {
        final localZone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(localZone.identifier));
      } catch (e) {
        debugPrint('NotificationService: local timezone lookup failed: $e');
      }

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/launcher_icon'),
          iOS: DarwinInitializationSettings(),
          macOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (response) =>
            _handlePayload(response.payload),
      );

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService: initialization failed: $e');
    }
  }

  /// Asks the OS for permission to post notifications (needed on Android 13+
  /// and iOS). Safe to call more than once — the OS only prompts once.
  Future<void> requestPermissions() async {
    if (!_initialized) return;

    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission();
        case TargetPlatform.iOS:
          await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, sound: true, badge: true);
        case TargetPlatform.macOS:
          await _plugin
              .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, sound: true, badge: true);
        default:
          break;
      }
    } catch (e) {
      debugPrint('NotificationService: permission request failed: $e');
    }
  }

  /// Schedules (or clears) the repeating daily reminder.
  Future<void> applyDailyReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    if (!_initialized) return;

    if (!enabled) {
      await cancelDailyReminder();
      return;
    }

    try {
      // Replace any previously scheduled reminder so the time never duplicates.
      await _plugin.cancel(id: dailyReminderId);

      await _plugin.zonedSchedule(
        id: dailyReminderId,
        title: 'திருவாசகம் 📖',
        body: 'இன்றைய பாடலைப் படிக்க அல்லது கேட்க நேரம்!',
        scheduledDate: _nextInstanceOf(hour, minute),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        // Inexact alarms need no special permission and still fire every day
        // around the chosen minute.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        // This is what makes it repeat daily instead of firing only once.
        matchDateTimeComponents: DateTimeComponents.time,
        payload: dailyReminderPayload,
      );
    } catch (e) {
      debugPrint('NotificationService: scheduling failed: $e');
    }
  }

  Future<void> cancelDailyReminder() async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id: dailyReminderId);
    } catch (e) {
      debugPrint('NotificationService: cancel failed: $e');
    }
  }

  /// Reads the notification that launched the app, if any. Call this after
  /// [initialize] and after setting [onDailyReminderTap].
  Future<void> handleLaunchFromNotification() async {
    if (!_initialized) return;

    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        if (details?.notificationResponse?.payload == dailyReminderPayload) {
          // The app is still starting up (splash screen), so defer the tap.
          _pendingDailyReminderTap = true;
        }
      }
    } catch (e) {
      debugPrint('NotificationService: launch details failed: $e');
    }
  }

  /// Returns true once when the user launched the app by tapping the reminder.
  bool consumePendingDailyReminderTap() {
    final pending = _pendingDailyReminderTap;
    _pendingDailyReminderTap = false;
    return pending;
  }

  void _handlePayload(String? payload) {
    if (payload != dailyReminderPayload) return;

    if (onDailyReminderTap != null) {
      onDailyReminderTap!();
    } else {
      _pendingDailyReminderTap = true;
    }
  }

  /// Today at [hour]:[minute], or tomorrow if that time already passed.
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    return scheduled.isAfter(now)
        ? scheduled
        : scheduled.add(const Duration(days: 1));
  }
}
