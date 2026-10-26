import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fittrack_mobile/core/network/api_client.dart';
import 'package:fittrack_mobile/features/auth/auth_session.dart';
import 'package:fittrack_mobile/features/catalog/catalog_import_screen.dart';

class _ImportAdapter implements HttpClientAdapter {
  int commits = 0;
  int previews = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    if (stream != null) {
      await stream.drain<void>();
    }
    final commit = options.path.endsWith('/commit');
    if (commit) commits++;
    if (!commit) previews++;
    return ResponseBody.fromString(
      jsonEncode({
        'id': 'batch',
        'kind': 'EXERCISE',
        'committedAt': commit ? '2026-10-25T12:00:00' : null,
        'rows': [
          {
            'number': 2,
            'values': {'name': 'Smith Squat'},
            'before': {},
            'after': {'name': 'Smith Squat'},
            'errors': [],
            'warnings': [],
            'suggestedAction': 'CREATE',
            'resultId': commit ? 'new-id' : null,
          },
        ],
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets(
    'admin import at 360px requires preview, checkbox and final confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final adapter = _ImportAdapter();
      final api = ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
          ..httpClientAdapter = adapter,
      );
      final session = AuthSession(api)
        ..user = const AuthUser(
          id: 'admin',
          email: 'admin@example.invalid',
          fullName: 'Admin',
          role: 'ADMIN',
          lunchEnabled: false,
          fitnessEnabled: true,
          healthEnabled: true,
          chatbotEnabled: true,
          todoEnabled: true,
          scheduleEnabled: true,
          passwordChangeRequired: false,
        );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiClient>.value(value: api),
            ChangeNotifierProvider<AuthSession>.value(value: session),
          ],
          child: const MaterialApp(home: CatalogImportScreen(kind: 'EXERCISE')),
        ),
      );
      await tester.pumpAndSettle();
      final scroll = find
          .descendant(
            of: find.byKey(const ValueKey('catalog-import-list')),
            matching: find.byType(Scrollable),
          )
          .first;
      final paste = find.widgetWithText(
        TextField,
        'Dán bảng (gồm dòng tiêu đề)',
      );
      await tester.scrollUntilVisible(paste, 200, scrollable: scroll);
      await tester.enterText(
        paste,
        'name\tmuscleGroup\tequipment\nSmith Squat\tLegs\tSmith',
      );
      await tester.pumpAndSettle();
      final preview = find.text('Kiểm tra và xem trước');
      await tester.scrollUntilVisible(preview, 200, scrollable: scroll);
      await tester.tap(preview);
      await tester.pumpAndSettle();
      expect(
        adapter.previews,
        1,
        reason: find
            .byType(Text)
            .evaluate()
            .map((e) => (e.widget as Text).data)
            .join('\n'),
      );
      final commit = find.text('Xác nhận nhập 1 dòng');
      await tester.scrollUntilVisible(commit, 200, scrollable: scroll);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Xác nhận nhập 1 dòng'),
            )
            .onPressed,
        isNull,
      );
      expect(adapter.commits, 0);
      final confirm = find.byType(CheckboxListTile);
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      await tester.ensureVisible(commit);
      await tester.tap(commit);
      await tester.pumpAndSettle();
      expect(adapter.commits, 0);
      await tester.tap(find.text('Xác nhận ghi'));
      await tester.pumpAndSettle();
      expect(adapter.commits, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
      api.activity.dispose();
      api.dio.close();
    },
  );
}
