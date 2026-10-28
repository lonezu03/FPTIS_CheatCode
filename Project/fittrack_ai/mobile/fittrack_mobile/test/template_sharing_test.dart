import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fittrack_mobile/core/network/api_client.dart';
import 'package:fittrack_mobile/features/auth/auth_session.dart';
import 'package:fittrack_mobile/features/sharing/template_sharing_screen.dart';

class _Api extends ApiClient {
  int writes = 0;
  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (path == '/workout-plans/page')
      return {
        'content': [
          {'id': 'plan', 'name': 'Mẫu tập'},
        ],
        'totalPages': 1,
      };
    return {'content': [], 'totalPages': 0};
  }

  @override
  Future<dynamic> post(String path, {Object? data}) async {
    writes++;
    return {};
  }
}

void main() {
  test('preview labels actual foods and exercises without raw payload', () {
    expect(
      sharingTemplateLines(
        {
          'name': 'Mẫu',
          'items': [
            {'foodId': 'rice', 'servingAmount': 1, 'servingUnit': 'SERVING'},
          ],
        },
        {'rice': 'Cơm'},
      ),
      ['Mẫu', 'Cơm · 1 khẩu phần'],
    );
  });
  testWidgets(
    'narrow sharing screen does not write on open and requires explicit send confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = _Api();
      final session = AuthSession(api)
        ..user = AuthUser(
          id: 'u',
          email: 'u@example.test',
          fullName: 'User',
          role: 'USER',
          lunchEnabled: false,
          fitnessEnabled: true,
          healthEnabled: false,
          chatbotEnabled: false,
          todoEnabled: false,
          scheduleEnabled: false,
          passwordChangeRequired: false,
        );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiClient>.value(value: api),
            ChangeNotifierProvider<AuthSession>.value(value: session),
          ],
          child: const MaterialApp(home: TemplateSharingScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(api.writes, 0);
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField), 'other@example.test');
      await tester.tap(find.text('Bản mẫu của bạn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mẫu tập').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Gửi bản mẫu — 7 ngày'));
      await tester.tap(find.text('Gửi bản mẫu — 7 ngày'));
      await tester.pumpAndSettle();
      expect(find.text('Xác nhận'), findsWidgets);
      expect(api.writes, 0);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(api.writes, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
