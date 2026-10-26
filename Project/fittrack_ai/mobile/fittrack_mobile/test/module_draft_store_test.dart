import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fittrack_mobile/core/storage/module_draft_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'drafts are owner scoped and cleanup does not delete other credentials',
    () async {
      const storage = FlutterSecureStorage();
      await storage.write(key: 'fittrack_access_token', value: 'test');
      await ModuleDraftStore.write('owner-one', 'plan', {'name': 'A'});
      await ModuleDraftStore.write('owner-two', 'plan', {'name': 'B'});
      expect(await ModuleDraftStore.read('owner-one', 'plan'), {'name': 'A'});
      await ModuleDraftStore.clearOwner('owner-one');
      expect(await ModuleDraftStore.read('owner-one', 'plan'), isNull);
      expect(await ModuleDraftStore.read('owner-two', 'plan'), {'name': 'B'});
      expect(await storage.read(key: 'fittrack_access_token'), 'test');
    },
  );
  test('expired draft is discarded rather than restored', () async {
    const storage = FlutterSecureStorage();
    await storage.write(
      key: 'fittrack_draft_owner:plan',
      value: jsonEncode({
        'expiresAt': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
        'data': {'name': 'old'},
      }),
    );
    expect(await ModuleDraftStore.read('owner', 'plan'), isNull);
    expect(await storage.read(key: 'fittrack_draft_owner:plan'), isNull);
  });
}
