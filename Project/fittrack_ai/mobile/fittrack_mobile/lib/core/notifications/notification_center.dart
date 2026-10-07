import 'dart:async';

import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import 'background_notification_worker.dart';
import 'native_notification_service.dart';
import 'notification_sync_service.dart';

class NotificationCenter extends ChangeNotifier {
  NotificationCenter(ApiClient api, {NotificationSyncService? syncService})
    : _syncService = syncService ?? NotificationSyncService(api);

  final NotificationSyncService _syncService;
  Timer? _timer;
  bool _started = false;
  bool _deliveringNative = false;
  bool loading = false;
  bool? permissionGranted;
  int unreadCount = 0;
  List<Map<String, dynamic>> items = const [];
  Object? error;
  DateTime? lastSyncedAt;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    // The in-app inbox is useful even when notification permissions or the
    // background scheduler are unavailable on this device.
    await refresh();
    if (!_started) return;
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => refresh());
    unawaited(_prepareSystemNotifications());
  }

  Future<void> _prepareSystemNotifications() async {
    try {
      await NativeNotificationService.initialize();
      await refreshPermissionStatus();
    } catch (exception) {
      permissionGranted = false;
      debugPrint('Unable to initialize local notifications: $exception');
    }
    if (_started) {
      try {
        await registerNotificationBackgroundTask();
      } catch (exception) {
        debugPrint('Unable to schedule background notifications: $exception');
      }
    }
  }

  Future<bool> refreshPermissionStatus() async {
    final wasDenied = permissionGranted == false;
    permissionGranted = await NativeNotificationService.notificationsEnabled();
    if (wasDenied && permissionGranted == true) {
      await _syncService.clearNativeDeliveryHistory();
      await refresh();
    }
    notifyListeners();
    return permissionGranted ?? false;
  }

  Future<bool> requestPermission() async {
    permissionGranted = await NativeNotificationService.requestPermission();
    notifyListeners();
    if (permissionGranted == true) {
      await _syncService.clearNativeDeliveryHistory();
      await NativeNotificationService.showPermissionConfirmation();
      await refresh();
    }
    return permissionGranted ?? false;
  }

  Future<void> openPermissionSettings() async {
    await NativeNotificationService.openNotificationSettings();
  }

  Future<bool> testSystemNotification() async {
    var granted = await refreshPermissionStatus();
    if (!granted) granted = await requestPermission();
    if (!granted) return false;
    return NativeNotificationService.showTestNotification();
  }

  Future<void> stop({bool cancelBackground = false}) async {
    _timer?.cancel();
    _timer = null;
    _started = false;
    unreadCount = 0;
    items = const [];
    error = null;
    lastSyncedAt = null;
    if (cancelBackground) await cancelNotificationBackgroundTask();
    notifyListeners();
  }

  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final snapshot = await _syncService.sync(showNative: false);
      if (!_started) return;
      unreadCount = snapshot.unreadCount;
      items = snapshot.items;
      lastSyncedAt = DateTime.now();
      if (!_deliveringNative) {
        _deliveringNative = true;
        unawaited(_deliverNative(snapshot.items));
      }
    } catch (exception) {
      error = exception;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _deliverNative(List<Map<String, dynamic>> notifications) async {
    try {
      await _syncService.deliverNative(notifications);
    } catch (exception) {
      debugPrint('Unable to deliver native notifications: $exception');
    } finally {
      _deliveringNative = false;
    }
  }

  Future<void> markRead(String id) async {
    await _syncService.api.patch('/notifications/$id/read');
    await refresh();
  }

  Future<void> markAllRead() async {
    await _syncService.api.post('/notifications/read-all');
    await refresh();
  }
}
