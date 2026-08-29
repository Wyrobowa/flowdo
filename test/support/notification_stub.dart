import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = MethodChannel('dexterous.com/flutter/local_notifications');

/// Method names sent to the notification plugin since the last
/// [stubNotificationPlugin] call, in order.
final List<String> notificationCalls = [];

/// `flutter_local_notifications` never registers a platform instance under a
/// test binding, so any call out of `NotificationService` throws a
/// `LateInitializationError`. Registering the Android implementation and
/// stubbing its method channel makes those calls no-ops that tests can run
/// through, and records what was sent.
void stubNotificationPlugin() {
  AndroidFlutterLocalNotificationsPlugin.registerWith();
  notificationCalls.clear();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, (call) async {
    notificationCalls.add(call.method);
    switch (call.method) {
      // The calls whose return value the plugin actually reads.
      case 'initialize':
      case 'canScheduleExactNotifications':
      case 'requestNotificationsPermission':
      case 'requestExactAlarmsPermission':
        return true;
      default:
        return null;
    }
  });
}

void clearNotificationStub() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, null);
}
