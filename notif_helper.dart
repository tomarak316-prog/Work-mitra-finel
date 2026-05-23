// lib/utils/notif_helper.dart
import 'package:flutter/material.dart' show Color, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotifHelper {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    const channel = AndroidNotificationChannel(
      'work_mitra_channel',
      'Work Mitra Alerts',
      description: 'Job alerts, applications, messages',
      importance: Importance.high,
      playSound: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _ready = true;
  }

  static Future<void> show({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    if (!_ready) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'work_mitra_channel',
        'Work Mitra Alerts',
        channelDescription: 'Job alerts and updates',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xFF16a34a),
      ),
    );
    await _plugin.show(id, title, body, details, payload: payload);
  }
}
