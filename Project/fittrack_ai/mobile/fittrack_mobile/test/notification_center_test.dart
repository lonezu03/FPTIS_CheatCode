import 'package:fittrack_mobile/core/network/api_client.dart';
import 'package:fittrack_mobile/core/notifications/notification_center.dart';
import 'package:fittrack_mobile/core/notifications/notification_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeNotificationSyncService extends NotificationSyncService {
  _FakeNotificationSyncService(super.api);

  int fetches = 0;
  Object? fetchError;
  Object? deliveryError;

  @override
  Future<NotificationSnapshot> sync({bool showNative = true}) async {
    fetches++;
    if (fetchError case final error?) throw error;
    return const NotificationSnapshot(
      unreadCount: 1,
      items: [
        {'id': 'new-notification', 'title': 'Lời nhắc mới', 'readAt': null},
      ],
    );
  }

  @override
  Future<void> deliverNative(List<Map<String, dynamic>> items) async {
    if (deliveryError case final error?) throw error;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('in-app inbox loads as soon as notification center starts', () async {
    final api = ApiClient();
    final sync = _FakeNotificationSyncService(api);
    final center = NotificationCenter(api, syncService: sync);

    await center.start();

    expect(sync.fetches, 1);
    expect(center.unreadCount, 1);
    expect(center.items.single['title'], 'Lời nhắc mới');
    expect(center.error, isNull);

    await center.stop();
    center.dispose();
    api.activity.dispose();
  });

  test('API failure is visible and a later refresh recovers', () async {
    final api = ApiClient();
    final sync = _FakeNotificationSyncService(api);
    final center = NotificationCenter(api, syncService: sync);
    sync.fetchError = StateError('Backend unavailable');

    await center.start();
    expect(center.error, isA<StateError>());
    expect(center.items, isEmpty);

    sync.fetchError = null;
    await center.refresh();
    expect(center.error, isNull);
    expect(center.unreadCount, 1);

    await center.stop();
    center.dispose();
    api.activity.dispose();
  });

  test('native delivery failure does not erase the in-app inbox', () async {
    final api = ApiClient();
    final sync = _FakeNotificationSyncService(api)
      ..deliveryError = StateError('Notification permission unavailable');
    final center = NotificationCenter(api, syncService: sync);

    await center.start();
    await Future<void>.delayed(Duration.zero);

    expect(center.error, isNull);
    expect(center.unreadCount, 1);
    expect(center.items.single['id'], 'new-notification');

    await center.stop();
    center.dispose();
    api.activity.dispose();
  });
}
