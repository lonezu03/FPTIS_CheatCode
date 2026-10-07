import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../network/api_client.dart';
import 'native_notification_service.dart';

class NotificationSnapshot {
  const NotificationSnapshot({required this.unreadCount, required this.items});

  final int unreadCount;
  final List<Map<String, dynamic>> items;
}

class NotificationSyncService {
  NotificationSyncService(this.api, {FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const knownIdsKey = 'fittrack_known_notification_ids';

  final ApiClient api;
  final FlutterSecureStorage _storage;

  Future<void> clearNativeDeliveryHistory() =>
      _storage.delete(key: knownIdsKey);

  Future<NotificationSnapshot> sync({bool showNative = true}) async {
    final response = await api.get('/notifications');
    final map = Map<String, dynamic>.from(response as Map);
    final rawItems = map['notifications'];
    final items = rawItems is List
        ? rawItems
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList()
        : <Map<String, dynamic>>[];

    final snapshot = NotificationSnapshot(
      unreadCount:
          (map['unreadCount'] as num?)?.toInt() ??
          items.where((item) => item['readAt'] == null).length,
      items: items,
    );
    // A failure in Android permissions, plugin initialization or local storage
    // must never hide notifications that the backend already returned.
    if (showNative) {
      try {
        await deliverNative(items);
      } catch (error) {
        debugPrint('Unable to deliver native notifications: $error');
      }
    }
    return snapshot;
  }

  Future<void> deliverNative(List<Map<String, dynamic>> items) async {
    if (!await NativeNotificationService.notificationsEnabled()) return;
    final known = _decodeIds(await _storage.read(key: knownIdsKey));
    final currentIds = items
        .map((item) => item['id']?.toString())
        .whereType<String>()
        .toSet();
    final newUnread = items.where(
      (item) =>
          item['readAt'] == null &&
          item['id'] != null &&
          !known.contains(item['id'].toString()),
    );
    final delivered = <String>{};
    for (final notification in newUnread.take(3)) {
      if (await NativeNotificationService.show(notification)) {
        delivered.add(notification['id'].toString());
      }
    }
    // Only mark items actually displayed, plus already-known IDs. Older unread
    // items stay eligible for the next poll when more than three arrive at once.
    await _storage.write(
      key: knownIdsKey,
      value: jsonEncode(
        known.union(delivered).intersection(currentIds).take(100).toList(),
      ),
    );
  }

  static Set<String> _decodeIds(String? value) {
    if (value == null || value.isEmpty) return <String>{};
    try {
      final decoded = jsonDecode(value);
      return decoded is List
          ? decoded.map((item) => item.toString()).toSet()
          : <String>{};
    } catch (_) {
      return <String>{};
    }
  }
}
