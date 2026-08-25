import 'dart:convert';

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

  Future<NotificationSnapshot> sync({bool showNative = true}) async {
    final response = await api.get('/notifications');
    final map = Map<String, dynamic>.from(response as Map);
    final rawItems = map['notifications'];
    final items = rawItems is List
        ? rawItems
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList()
        : <Map<String, dynamic>>[];

    final stored = await _storage.read(key: knownIdsKey);
    final known = _decodeIds(stored);
    final currentIds = items
        .map((item) => item['id']?.toString())
        .whereType<String>()
        .toSet();

    if (stored != null && showNative) {
      final newUnread = items.where(
        (item) =>
            item['readAt'] == null &&
            item['id'] != null &&
            !known.contains(item['id'].toString()),
      );
      for (final notification in newUnread.take(3)) {
        await NativeNotificationService.show(notification);
      }
    }

    await _storage.write(
      key: knownIdsKey,
      value: jsonEncode(currentIds.take(100).toList()),
    );
    return NotificationSnapshot(
      unreadCount:
          (map['unreadCount'] as num?)?.toInt() ??
          items.where((item) => item['readAt'] == null).length,
      items: items,
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
