import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fittrack_mobile/core/network/api_client.dart';
import 'package:fittrack_mobile/features/auth/auth_session.dart';
import 'package:fittrack_mobile/features/finance/shared_expenses_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _Adapter implements HttpClientAdapter {
  final writes = <Map<String, dynamic>>[];
  bool accepted = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    dynamic result;
    if (options.method == 'POST') {
      writes.add(Map<String, dynamic>.from(options.data as Map));
      accepted = true;
      result = {'id': 'group', 'action': 'ACCEPT'};
    } else if (options.path.endsWith('/invitations')) {
      result = {
        'content': accepted
            ? []
            : [
                {
                  'groupId': 'group',
                  'groupName': 'Bạn bè',
                  'invitedBy': 'An',
                  'version': 7,
                },
              ],
        'totalPages': 1,
      };
    } else {
      result = {'content': [], 'totalPages': 0};
    }
    return ResponseBody.fromString(
      jsonEncode(result),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _PreviewAdapter implements HttpClientAdapter {
  final previews = <Completer<ResponseBody>>[];
  final writes = <Map<String, dynamic>>[];

  ResponseBody json(dynamic value) => ResponseBody.fromString(
    jsonEncode(value),
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/expenses/preview')) {
      final response = Completer<ResponseBody>();
      previews.add(response);
      return response.future;
    }
    if (options.method == 'POST') {
      writes.add(Map<String, dynamic>.from(options.data as Map));
      return json({});
    }
    if (options.path.endsWith('/groups/group')) {
      return json({
        'group': {
          'id': 'group',
          'name': 'Nhóm test',
          'ownerId': 'u',
          'myStatus': 'ACTIVE',
          'archived': false,
          'version': 1,
        },
        'members': [
          {'userId': 'u', 'name': 'Người dùng', 'status': 'ACTIVE', 'acceptedAt': '2026-01-01'},
          {'userId': 'v', 'name': 'Bạn bè', 'status': 'ACTIVE', 'acceptedAt': '2026-01-01'},
        ],
      });
    }
    if (options.path.endsWith('/groups')) {
      return json({
        'content': [
          {'id': 'group', 'name': 'Nhóm test', 'myStatus': 'ACTIVE'},
        ],
        'totalPages': 1,
      });
    }
    return json({'content': [], 'totalPages': 0});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets('group, invite and settlement dialogs close without disposed controllers', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final adapter = _PreviewAdapter();
    final api = ApiClient(dio: Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
      ..httpClientAdapter = adapter);
    final session = AuthSession(api)
      ..user = const AuthUser(id: 'u', email: 'u@example.invalid', fullName: 'Người dùng',
        role: 'USER', lunchEnabled: false, fitnessEnabled: true, healthEnabled: true,
        chatbotEnabled: false, todoEnabled: true, scheduleEnabled: true,
        financeEnabled: true, passwordChangeRequired: false);
    await tester.pumpWidget(MultiProvider(
      providers: [Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider<AuthSession>.value(value: session)],
      child: const MaterialApp(home: SharedExpensesScreen()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo nhóm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nhóm test').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Mời thành viên'));
    await tester.tap(find.text('Mời thành viên'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Đề nghị'));
    await tester.tap(find.text('Đề nghị'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(adapter.writes, isEmpty);
  });
  testWidgets('late preview is discarded after amount changes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final adapter = _PreviewAdapter();
    final api = ApiClient(
      dio: Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
        ..httpClientAdapter = adapter,
    );
    final session = AuthSession(api)
      ..user = const AuthUser(
        id: 'u',
        email: 'u@example.invalid',
        fullName: 'Người dùng',
        role: 'USER',
        lunchEnabled: false,
        fitnessEnabled: true,
        healthEnabled: true,
        chatbotEnabled: false,
        todoEnabled: true,
        scheduleEnabled: true,
        financeEnabled: true,
        passwordChangeRequired: false,
      );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: api),
          ChangeNotifierProvider<AuthSession>.value(value: session),
        ],
        child: const MaterialApp(home: SharedExpensesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nhóm test').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm'));
    await tester.pumpAndSettle();
    Finder field(String label) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );
    await tester.enterText(field('Nội dung'), 'Ăn trưa');
    await tester.enterText(field('Số tiền (đồng)'), '100');
    await tester.tap(find.text('Xem trước phần chia'));
    await tester.pumpAndSettle();
    expect(adapter.previews, hasLength(1));
    await tester.enterText(field('Số tiền (đồng)'), '200');
    adapter.previews.first.complete(
      adapter.json([
        {'userId': 'u', 'amount': 100},
      ]),
    );
    await tester.pumpAndSettle();
    final save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Lưu khoản chi'),
    );
    expect(save.onPressed, isNull);
    expect(adapter.writes, isEmpty);
    await tester.tap(find.text('Xem trước phần chia'));
    await tester.pumpAndSettle();
    expect(adapter.previews, hasLength(2));
    adapter.previews.last.complete(
      adapter.json([
        {'userId': 'u', 'amount': 200},
      ]),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu khoản chi'));
    await tester.pumpAndSettle();
    expect(adapter.writes.single['amount'], 200);
  });
  testWidgets(
    'invitation consent is explicit and sends version and operation id',
    (tester) async {
      final adapter = _Adapter();
      final api = ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
          ..httpClientAdapter = adapter,
      );
      final session = AuthSession(api)
        ..user = const AuthUser(
          id: 'u',
          email: 'u@example.invalid',
          fullName: 'Người dùng',
          role: 'USER',
          lunchEnabled: false,
          fitnessEnabled: true,
          healthEnabled: true,
          chatbotEnabled: false,
          todoEnabled: true,
          scheduleEnabled: true,
          financeEnabled: true,
          passwordChangeRequired: false,
        );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiClient>.value(value: api),
            ChangeNotifierProvider<AuthSession>.value(value: session),
          ],
          child: const MaterialApp(home: SharedExpensesScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Chấp nhận'));
      await tester.pumpAndSettle();
      expect(adapter.writes, isEmpty);
      expect(find.textContaining('kể cả sau khi rời nhóm'), findsWidgets);
      await tester.tap(find.text('Xác nhận').last);
      await tester.pumpAndSettle();
      expect(adapter.writes, hasLength(1));
      expect(adapter.writes.single['action'], 'ACCEPT');
      expect(adapter.writes.single['version'], 7);
      expect(
        (adapter.writes.single['operationId'] as String).length,
        greaterThanOrEqualTo(8),
      );
    },
  );
}
