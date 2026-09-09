import 'package:fittrack_mobile/core/network/api_activity_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('theo dõi request đọc và ghi, chỉ kết thúc một lần', () {
    final activity = ApiActivityController();
    var notifications = 0;
    activity.addListener(() => notifications += 1);

    final finishRead = activity.begin(isMutation: false);
    final finishWrite = activity.begin(isMutation: true);
    expect(activity.pendingRequests, 2);
    expect(activity.pendingMutations, 1);
    expect(activity.isMutating, isTrue);

    finishRead();
    finishRead();
    finishWrite();
    expect(activity.pendingRequests, 0);
    expect(activity.pendingMutations, 0);
    expect(notifications, 4);
    activity.dispose();
  });

  test('chặn mutation trùng cho tới khi request trước được giải phóng', () {
    final guard = ApiMutationGuard();
    final release = guard.acquire('POST:/orders:{portion:1}');

    expect(release, isNotNull);
    expect(guard.acquire('POST:/orders:{portion:1}'), isNull);
    expect(guard.acquire('POST:/orders:{portion:2}'), isNotNull);

    release?.call();
    expect(guard.acquire('POST:/orders:{portion:1}'), isNotNull);
  });
}
