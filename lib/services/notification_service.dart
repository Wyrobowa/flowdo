import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/task.dart';
import '../providers/session_provider.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _tzInitialized = false;

  static Future<void> init() async {
    if (kIsWeb) return;
    if (!_tzInitialized) {
      tz.initializeTimeZones();
      _tzInitialized = true;
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      // Show banner/alert even while the app is in the foreground
      defaultPresentAlert: true,
      defaultPresentBanner: true,
      defaultPresentSound: false, // we play our own sounds
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin, macOS: darwin),
    );
  }

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// Requests system notification permission. Returns true if granted.
  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    final android = _android;
    if (android != null) {
      // Android 13+ requires POST_NOTIFICATIONS to be granted at runtime.
      return await android.requestNotificationsPermission() ?? false;
    }

    bool granted = false;
    final macOS = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    if (macOS != null) {
      granted = await macOS.requestPermissions(
            alert: true, badge: true, sound: true) ??
          false;
    }
    final iOS = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iOS != null) {
      granted = await iOS.requestPermissions(
            alert: true, badge: true, sound: true) ??
          false;
    }
    if (macOS == null && iOS == null) granted = true;
    return granted;
  }

  /// Whether alerts can be scheduled to fire at an exact time. Only ever false
  /// on Android 12+, where the exact-alarm permission is granted separately.
  static Future<bool> canScheduleExact() async {
    if (kIsWeb) return false;
    final android = _android;
    if (android == null) return true;
    return await android.canScheduleExactNotifications() ?? false;
  }

  /// Sends the user to the system screen where exact alarms are granted.
  /// Android-only; returns false if there was nothing to ask for.
  static Future<bool> requestExactAlarms() async {
    if (kIsWeb) return false;
    final android = _android;
    if (android == null) return false;
    return await android.requestExactAlarmsPermission() ?? false;
  }

  static Future<void> show(String title, String body) async {
    if (kIsWeb) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'flowdo_timer',
        'Flowdo Timer',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
    await _plugin.show(0, title, body, details);
  }

  static Future<void> schedule(
    String id,
    String title,
    String body,
    DateTime when,
  ) async {
    if (kIsWeb) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'flowdo_timer',
        'Flowdo Timer',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
    final tzWhen = tz.TZDateTime.from(when, tz.local);
    // Scheduling an exact alarm without the permission throws, so downgrade to
    // an inexact one instead of losing the alert entirely.
    final mode = await canScheduleExact()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    try {
      await _plugin.zonedSchedule(
        id.hashCode,
        title,
        body,
        tzWhen,
        details,
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } on PlatformException catch (e) {
      // The permission can be revoked between the check and the call.
      debugPrint('Could not schedule notification "$id": ${e.code}');
    }
  }

  static Future<void> cancel(String id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id.hashCode);
  }

  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  static Future<void> schedulePhaseEnd(
    Task? task,
    SessionPhase phase,
    DateTime dueAt,
  ) async {
    final title = phase == SessionPhase.focus
        ? 'Focus complete!'
        : 'Break over!';
    final body = phase == SessionPhase.focus
        ? (task?.title.isNotEmpty == true ? task!.title : 'Time for a break.')
        : 'Time to get back to work';
    await schedule('phase_end', title, body, dueAt);
  }
}
