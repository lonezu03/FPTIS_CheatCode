import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NativeNotificationService {
  NativeNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return false;
  }

  static Future<void> show(Map<String, dynamic> notification) async {
    if (kIsWeb) return;
    await initialize();
    final id = _stableId(
      notification['id']?.toString() ?? notification.toString(),
    );
    await _plugin.show(
      id: id,
      title: notification['title']?.toString() ?? 'FitTrack',
      body: notification['message']?.toString() ?? 'Bạn có thông báo mới.',
      payload: notification['id']?.toString(),
      notificationDetails: _detailsFor(notification['type']?.toString()),
    );
  }

  static NotificationDetails _detailsFor(String? type) {
    return switch (type) {
      'LUNCH_MENU_AVAILABLE' => const NotificationDetails(
        android: AndroidNotificationDetails(
          'fittrack_lunch_menu_v1',
          'Menu cơm mới',
          channelDescription:
              'Thông báo sau khi quản trị viên import và mở menu cơm',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_launcher',
          playSound: true,
          sound: RawResourceAndroidNotificationSound('lunch_menu_available'),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'lunch_menu_available.wav',
        ),
      ),
      'LUNCH_MENU_CLOSED' => const NotificationDetails(
        android: AndroidNotificationDetails(
          'fittrack_lunch_closed_v1',
          'Chốt đặt cơm',
          channelDescription: 'Thông báo khi menu cơm đã chốt nhận đơn',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_launcher',
          playSound: true,
          sound: RawResourceAndroidNotificationSound('lunch_order_closed'),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'lunch_order_closed.wav',
        ),
      ),
      _ => const NotificationDetails(
        android: AndroidNotificationDetails(
          'fittrack_updates',
          'Thông báo FitTrack',
          channelDescription:
              'Thanh toán, sức khỏe và thông báo từ quản trị viên',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    };
  }

  static int _stableId(String value) {
    var hash = 0;
    for (final code in value.codeUnits) {
      hash = ((hash * 31) + code) & 0x7fffffff;
    }
    return hash;
  }
}
