import 'package:flutter_local_notifications/flutter_local_notifications.dart';

typedef OnNotificationTap = void Function(String payload);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  OnNotificationTap? _onTap;

  Future<void> initNotifications(OnNotificationTap onTap) async {
    _onTap = onTap;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload != null && _onTap != null) {
          _onTap!(payload);
        }
      },
    );
  }

  Future<void> showNotification(
      int id,
      String title,
      String body, {
        String? payload,
      }) async {
    const android = AndroidNotificationDetails(
      'expense_channel',
      'Expenses',
      channelDescription: 'Notifications for new SMS expenses',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: android);

    await _plugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }
}
