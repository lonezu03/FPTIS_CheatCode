import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NativeNotificationService {
  NativeNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _generalChannel = AndroidNotificationChannel(
    'fittrack_updates_v2',
    'Thông báo FitTrack',
    description: 'Nhắc việc, lịch, sức khỏe, tài chính và thông báo hệ thống',
    importance: Importance.high,
    playSound: true,
  );
  static const _reminderChannel = AndroidNotificationChannel(
    'fittrack_reminders_v1',
    'Lời nhắc FitTrack',
    description: 'Lời nhắc công việc, lịch trình, sức khỏe và nhật ký',
    importance: Importance.max,
    playSound: true,
  );

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_fittrack'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(_generalChannel);
      await android?.createNotificationChannel(_reminderChannel);
    }
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

  static Future<bool> notificationsEnabled() async {
    if (kIsWeb) return false;
    await initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled() ??
          false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final permissions = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();
      return permissions?.isEnabled ?? false;
    }
    return true;
  }

  static Future<void> openNotificationSettings() async {
    if (kIsWeb) return;
    await initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.openAppNotificationSettings();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.openAppNotificationSettings();
    }
  }

  static Future<void> show(Map<String, dynamic> notification) async {
    if (kIsWeb) return;
    await initialize();
    if (!await notificationsEnabled()) return;
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

  static Future<void> showPermissionConfirmation() async {
    await show(const {
      'id': 'fittrack-notification-permission-enabled',
      'type': 'SYSTEM',
      'title': 'Đã bật thông báo FitTrack',
      'message': 'Lời nhắc mới sẽ xuất hiện trực tiếp trên thanh thông báo điện thoại.',
    });
  }

  static Future<void> showTestNotification() async {
    await show({
      'id': 'fittrack-native-test-${DateTime.now().millisecondsSinceEpoch}',
      'type': 'SYSTEM',
      'title': 'Thông báo thử từ FitTrack',
      'message': 'Thông báo hệ thống đang hoạt động. Bạn có thể đưa app xuống nền để tiếp tục sử dụng.',
    });
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
          icon: 'ic_stat_fittrack',
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
          icon: 'ic_stat_fittrack',
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
      'HEALTH_REMINDER' ||
      'TODO_REMINDER' ||
      'SCHEDULE_REMINDER' ||
      'JOURNAL_REMINDER' => const NotificationDetails(
        android: AndroidNotificationDetails(
          'fittrack_reminders_v1',
          'Lời nhắc FitTrack',
          channelDescription:
              'Lời nhắc công việc, lịch trình, sức khỏe và nhật ký',
          importance: Importance.max,
          priority: Priority.max,
          icon: 'ic_stat_fittrack',
          playSound: true,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      _ => const NotificationDetails(
        android: AndroidNotificationDetails(
          'fittrack_updates_v2',
          'Thông báo FitTrack',
          channelDescription:
              'Nhắc việc, lịch, sức khỏe, tài chính và thông báo hệ thống',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_fittrack',
          playSound: true,
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
