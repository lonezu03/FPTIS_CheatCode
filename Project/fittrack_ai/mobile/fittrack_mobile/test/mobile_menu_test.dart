import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fittrack_mobile/core/network/api_client.dart';
import 'package:fittrack_mobile/features/auth/auth_session.dart';
import 'package:fittrack_mobile/features/home/mobile_menu_controller.dart';
import 'package:fittrack_mobile/features/home/more_screen.dart';
import 'package:fittrack_mobile/features/admin/mobile_menu_settings_screen.dart';
import 'package:fittrack_mobile/core/notifications/notification_center.dart';

class _MenuApi extends ApiClient {
  List<Map<String, dynamic>> rows = mobileModuleLabels.keys
      .map((key) => {'key': key, 'visible': true})
      .toList();
  int version = 0;
  final writes = <Map<String, dynamic>>[];
  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async => {'version': version, 'modules': rows};
  @override
  Future<dynamic> put(String path, {Object? data}) async {
    final value = Map<String, dynamic>.from(data as Map);
    writes.add(value);
    version++;
    rows = (value['modules'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return {'version': version, 'modules': rows};
  }
}

AuthUser _user(String role, {bool fitness = true}) => AuthUser(
  id: 'u',
  email: 'u@example.invalid',
  fullName: 'User',
  role: role,
  lunchEnabled: false,
  fitnessEnabled: fitness,
  healthEnabled: true,
  chatbotEnabled: true,
  todoEnabled: true,
  scheduleEnabled: true,
  passwordChangeRequired: false,
);

void main() {
  testWidgets('admin menu save requires confirmation and applies visibility', (
    tester,
  ) async {
    final api = _MenuApi();
    final session = AuthSession(api)..user = _user('ADMIN');
    final menu = MobileMenuController(api);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: api),
          ChangeNotifierProvider<AuthSession>.value(value: session),
        ],
        child: MaterialApp(home: MobileMenuSettingsScreen(menu: menu)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('menu-visible-fitness')));
    await tester.tap(find.text('Lưu cấu hình toàn bộ app'));
    await tester.pumpAndSettle();
    expect(api.writes, isEmpty);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(api.writes, isEmpty);
    await tester.tap(find.text('Lưu cấu hình toàn bộ app'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();
    expect(api.writes, hasLength(1));
    expect(menu.allows('fitness', session.user!), isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    menu.dispose();
    session.dispose();
    api.activity.dispose();
  });
  testWidgets(
    'hiding all modules still leaves admin recovery entry and no module links',
    (tester) async {
      final api = _MenuApi();
      final session = AuthSession(api)..user = _user('ADMIN');
      final menu = MobileMenuController(api)
        ..modules = mobileModuleLabels.keys
            .map((key) => {'key': key, 'visible': false})
            .toList();
      final notifications = NotificationCenter(api)..permissionGranted = true;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiClient>.value(value: api),
            ChangeNotifierProvider<AuthSession>.value(value: session),
            ChangeNotifierProvider<NotificationCenter>.value(
              value: notifications,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MoreScreen(user: session.user!, menu: menu),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sắp xếp menu app'), findsOneWidget);
      expect(find.text('Kho bài tập'), findsNothing);
      expect(find.text('Luyện tập'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      menu.dispose();
      notifications.dispose();
      session.dispose();
      api.activity.dispose();
    },
  );
  test('global visibility applies even to ADMIN and cannot grant module permission', () {
    final api = ApiClient();
    final menu = MobileMenuController(api);
    menu.modules = mobileModuleLabels.keys
        .map((key) => {'key': key, 'visible': key != 'fitness'})
        .toList();
    expect(menu.allows('fitness', _user('ADMIN')), isFalse);
    expect(menu.allows('exercises', _user('USER', fitness: false)), isFalse);
    expect(menu.allows('lunch', _user('USER')), isFalse);
    expect(menu.allows('foods', _user('ADMIN')), isTrue);
    menu.dispose();
    api.activity.dispose();
  });
  test('menu contract rejects duplicate/missing/unknown keys', () {
    final rows = mobileModuleLabels.keys
        .map((key) => {'key': key, 'visible': true})
        .toList();
    expect(
      MobileMenuController.parseMenu({'version': 0, 'modules': rows}).length,
      mobileModuleLabels.length,
    );
    expect(
      () => MobileMenuController.parseMenu({
        'version': 0,
        'modules': [...rows, rows.first],
      }),
      throwsFormatException,
    );
    expect(
      () => MobileMenuController.parseMenu({
        'version': 0,
        'modules': rows.skip(1).toList(),
      }),
      throwsFormatException,
    );
  });
  test('older read cannot overwrite configuration returned by save', () {
    final api = _MenuApi();
    final menu = MobileMenuController(api);
    final rows = mobileModuleLabels.keys
        .map((key) => {'key': key, 'visible': false})
        .toList();
    menu.accept({'version': 3, 'modules': rows});
    menu.accept({'version': 2, 'modules': api.rows});
    expect(menu.version, 3);
    expect(menu.modules.every((e) => e['visible'] == false), isTrue);
    menu.dispose();
    api.activity.dispose();
  });
}
