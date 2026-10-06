import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _kEnabled = 'reminder_enabled';
  static const _kHour = 'reminder_hour';
  static const _kMinute = 'reminder_minute';
  static const _kId = 1001;

  static Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      debugPrint('Timezone error: $e');
      tz.setLocalLocation(tz.getLocation('Europe/Moscow'));
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    if (await isEnabled()) {
      final time = await getTime();
      await _scheduleDaily(time.hour, time.minute);
    }
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabled) ?? false;
  }

  static Future<TimeOfDay> getTime() async {
    final prefs = await SharedPreferences.getInstance();
    return TimeOfDay(
      hour: prefs.getInt(_kHour) ?? 20,
      minute: prefs.getInt(_kMinute) ?? 0,
    );
  }

  static Future<void> enable(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, true);
    await prefs.setInt(_kHour, hour);
    await prefs.setInt(_kMinute, minute);
    await _scheduleDaily(hour, minute);
  }

  static Future<void> disable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, false);
    await _plugin.cancel(_kId);
  }

  static Future<void> updateTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kHour, hour);
    await prefs.setInt(_kMinute, minute);
    if (prefs.getBool(_kEnabled) ?? false) {
      await _plugin.cancel(_kId);
      await _scheduleDaily(hour, minute);
    }
  }

  static Future<void> _scheduleDaily(int hour, int minute) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, hour, minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _kId,
      '🚗 Пора записать одометр!',
      'Не забудь внести текущий пробег.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Ежедневное напоминание',
          channelDescription: 'Напоминание записать одометр',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> showNow() async {
    await _plugin.show(
      _kId,
      '🚗 Тестовое напоминание',
      'Так будет выглядеть ежедневное напоминание.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Ежедневное напоминание',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
