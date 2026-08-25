import 'dart:async';

import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import 'background_notification_worker.dart';
import 'native_notification_service.dart';
import 'notification_sync_service.dart';

class NotificationCenter extends ChangeNotifier {
  NotificationCenter(ApiClient api)
    : _syncService = NotificationSyncService(api);

  final NotificationSyncService _syncService;
  Timer? _timer;
  bool _started = false;
  bool loading = false;
  bool? permissionGranted;
  int unreadCount = 0;
  List<Map<String, dynamic>> items = const [];
  Object? error;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await NativeNotificationService.initialize();
    await refreshPermissionStatus();
    await registerNotificationBackgroundTask();
    await refresh();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => refresh());
  }

  Future<bool> refreshPermissionStatus() async {
    permissionGranted = await NativeNotificationService.notificationsEnabled();
    notifyListeners();
    return permissionGranted ?? false;
  }

  Future<bool> requestPermission() async {
    permissionGranted = await NativeNotificationService.requestPermission();
    notifyListeners();
    return permissionGranted ?? false;
  }

  Future<void> openPermissionSettings() async {
    await NativeNotificationService.openNotificationSettings();
  }

  Future<void> stop({bool cancelBackground = false}) async {
    _timer?.cancel();
    _timer = null;
    _started = false;
    unreadCount = 0;
    items = const [];
    error = null;
    if (cancelBackground) await cancelNotificationBackgroundTask();
    notifyListeners();
  }

  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final snapshot = await _syncService.sync();
      unreadCount = snapshot.unreadCount;
      items = snapshot.items;
    } catch (exception) {
      error = exception;
    } finally {
      loading = false;
      notifyListeners();
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
