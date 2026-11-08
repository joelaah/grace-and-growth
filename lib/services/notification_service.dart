import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Handles scheduling and delivery of peaceful daily sanctuary reminders.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initializes the local notification plugin across supported platforms.
  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      );

      await _notificationsPlugin.initialize(initSettings);
      _initialized = true;
    } catch (_) {
      // Graceful fallback on environments where native notifications aren't present
    }
  }

  /// Schedules a repeating daily notification at the specified [hour] and [minute].
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    String title = 'Grace & Growth',
    String body = 'A gentle Scripture moment awaits your heart today.',
  }) async {
    if (kIsWeb) return;

    try {
      await initialize();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('daily_notification_hour', hour);
      await prefs.setInt('daily_notification_minute', minute);
      await prefs.setBool('daily_notification_enabled', true);

      await cancelDailyReminder();

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'daily_verse_channel',
        'Daily Sanctuary Reminder',
        channelDescription: 'Gentle daily reminder to pause and reflect',
        importance: Importance.high,
        priority: Priority.high,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notificationsPlugin.zonedSchedule(
        1001,
        title,
        body,
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Handled cleanly
    }
  }

  /// Cancels the scheduled daily notification reminder.
  Future<void> cancelDailyReminder() async {
    if (kIsWeb) return;
    try {
      await _notificationsPlugin.cancel(1001);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('daily_notification_enabled', false);
    } catch (_) {}
  }

  /// Returns the saved daily notification reminder time, or null if disabled.
  Future<TimeOfDay?> getSavedReminderTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('daily_notification_enabled') ?? false;
      if (!enabled) return null;
      final hour = prefs.getInt('daily_notification_hour') ?? 8;
      final minute = prefs.getInt('daily_notification_minute') ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }
}
