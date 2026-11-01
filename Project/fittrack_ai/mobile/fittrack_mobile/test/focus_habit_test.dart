import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fittrack_mobile/core/network/api_client.dart';
import 'package:fittrack_mobile/features/planner/focus_screen.dart';
import 'package:fittrack_mobile/features/personal_tracking/habit_heatmap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _Adapter implements HttpClientAdapter {
  bool includeTodo = true;
  bool failFirstPost = false;
  int firstPostStatus = 500;
  bool failActive = false;
  bool failTodos = false;
  Completer<void>? delayedHistory;
  Completer<void>? delayedActiveAfterPost;
  bool returnSession = false;
  int activeReads = 0;
  Map<String, dynamic>? activeSession;
  final writes = <Map<String, dynamic>>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    dynamic body;
    var status = 200;
    if (options.method == 'POST') {
      writes.add(Map<String, dynamic>.from(options.data as Map));
      if (failFirstPost && writes.length == 1) {
        status = firstPostStatus;
        body = {'message': 'Không thể kết nối'};
      } else {
        body = returnSession
            ? {
                'id': 'session',
                'title': 'Đọc sách',
                'state': 'RUNNING',
                'elapsedSeconds': 0,
                'plannedSeconds': 1500,
                'version': 0,
              }
            : {'id': 'session'};
        if (returnSession)
          activeSession = Map<String, dynamic>.from(body as Map);
      }
    } else if (options.path.endsWith('/calendar')) {
      body = {
        'cells': [
          {'day': '2026-10-01', 'status': 'UNKNOWN'},
          {'day': '2026-10-02', 'status': 'REST'},
        ],
        'done': 0,
        'eligibleDays': 0,
        'completionRate': null,
        'currentStreak': 0,
        'longestStreak': 0,
        'historyVerified': false,
      };
    } else if (options.path.endsWith('/active')) {
      activeReads++;
      if (writes.isNotEmpty) await delayedActiveAfterPost?.future;
      if (failActive) {
        status = 500;
        body = {'message': 'Lỗi phiên'};
      } else {
        body = activeSession;
      }
    } else if (options.path.endsWith('/todos/page')) {
      if (failTodos) {
        status = 500;
        body = {'message': 'Lỗi công việc'};
      } else {
        body = {
          'content': includeTodo
              ? [
                  {'id': 'task-1', 'title': 'Việc đang chọn', 'status': 'OPEN'},
                ]
              : [],
        };
      }
    } else {
      if (options.path.endsWith('/todos/focus')) await delayedHistory?.future;
      body = {'content': []};
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Widget _app(_Adapter adapter, Widget child) => Provider<ApiClient>(
  create: (_) => ApiClient(
    dio: Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
      ..httpClientAdapter = adapter,
  ),
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  testWidgets('slow history does not hide active session or stop its refresh', (
    tester,
  ) async {
    final adapter = _Adapter()
      ..delayedHistory = Completer<void>()
      ..activeSession = {
        'id': 'session',
        'title': 'Đang tập trung',
        'state': 'RUNNING',
        'elapsedSeconds': 2,
        'plannedSeconds': 1500,
        'version': 0,
      };
    await tester.pumpWidget(_app(adapter, const FocusScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 16));
    expect(find.text('Đang tập trung'), findsOneWidget);
    expect(adapter.activeReads, 2);
    adapter.delayedHistory!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('slow history does not keep controls busy after starting', (
    tester,
  ) async {
    final adapter = _Adapter()..delayedHistory = Completer<void>();
    await tester.pumpWidget(_app(adapter, const FocusScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Đọc sách');
    await tester.tap(find.text('Bắt đầu'));
    await tester.pumpAndSettle();
    expect(adapter.writes, hasLength(1));
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Bắt đầu'))
          .onPressed,
      isNotNull,
    );
    adapter.delayedHistory!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'successful write immediately shows session while refresh is slow',
    (tester) async {
      final adapter = _Adapter()
        ..returnSession = true
        ..delayedActiveAfterPost = Completer<void>();
      await tester.pumpWidget(_app(adapter, const FocusScreen()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Đọc sách');
      await tester.tap(find.text('Bắt đầu'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 16));
      expect(find.text('Đọc sách'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Kết thúc'))
            .onPressed,
        isNotNull,
      );
      adapter.delayedActiveAfterPost!.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('todo errors allow manual title; active errors prohibit start', (
    tester,
  ) async {
    final adapter = _Adapter()..failTodos = true;
    await tester.pumpWidget(_app(adapter, const FocusScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Không tải được danh sách công việc'), findsOneWidget);
    expect(find.text('Tên phiên'), findsOneWidget);
    expect(find.text('Bắt đầu'), findsOneWidget);

    adapter.failActive = true;
    final refresh = tester
        .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
        .show();
    await tester.pumpAndSettle();
    await refresh;
    expect(find.text('Không kiểm tra được phiên tập trung'), findsOneWidget);
    expect(find.text('Bắt đầu'), findsNothing);
  });

  testWidgets('selected todo removed on refresh returns to manual title', (
    tester,
  ) async {
    final adapter = _Adapter();
    await tester.pumpWidget(_app(adapter, const FocusScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Việc đang chọn').last);
    await tester.pumpAndSettle();
    adapter.includeTodo = false;
    final refresh = tester
        .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
        .show();
    await tester.pumpAndSettle();
    await refresh;
    expect(tester.takeException(), isNull);
    expect(find.text('Tên phiên'), findsOneWidget);
  });

  testWidgets('retry after uncertain response uses the same operation id', (
    tester,
  ) async {
    final adapter = _Adapter()..failFirstPost = true;
    await tester.pumpWidget(_app(adapter, const FocusScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Đọc sách');
    await tester.tap(find.text('Bắt đầu'));
    await tester.pumpAndSettle();
    expect(adapter.writes, hasLength(1));
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Bắt đầu'))
          .onPressed,
      isNull,
    );
    final refresh = tester
        .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
        .show();
    await tester.pumpAndSettle();
    await refresh;
    await tester.tap(find.text('Thử lại thao tác'));
    await tester.pumpAndSettle();
    expect(adapter.writes, hasLength(2));
    expect(adapter.writes[1]['operationId'], adapter.writes[0]['operationId']);
  });

  testWidgets('HTTP 408 retains operation id and blocks another start', (tester) async {
    final adapter = _Adapter()..failFirstPost = true..firstPostStatus = 408;
    await tester.pumpWidget(_app(adapter, const FocusScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Đọc sách');
    await tester.tap(find.text('Bắt đầu'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Bắt đầu')).onPressed, isNull);
    await tester.tap(find.text('Thử lại thao tác'));
    await tester.pumpAndSettle();
    expect(adapter.writes, hasLength(2));
    expect(adapter.writes[1]['operationId'], adapter.writes[0]['operationId']);
  });

  testWidgets('habit map distinguishes unknown history from rest days', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _Adapter(),
        const HabitHeatmap(
          id: 'habit',
          from: '2026-10-01',
          to: '2026-10-02',
          revision: '1',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('2026-10-01: Chưa xác minh'), findsOneWidget);
    expect(find.byTooltip('2026-10-02: Ngày nghỉ'), findsOneWidget);
    expect(find.textContaining('không đưa vào tỷ lệ'), findsOneWidget);
    expect(find.textContaining('Ngày nghỉ không ngắt chuỗi'), findsOneWidget);
  });
}
