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
  final writes = <Map<String, dynamic>>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancelFuture) async {
    dynamic body;
    var status = 200;
    if (options.method == 'POST') {
      writes.add(Map<String, dynamic>.from(options.data as Map));
      if (failFirstPost && writes.length == 1) {
        status = 500;
        body = {'message': 'Không thể kết nối'};
      } else {
        body = {'id': 'session'};
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
      body = null;
    } else if (options.path.endsWith('/todos/page')) {
      body = {
        'content': includeTodo
            ? [{'id': 'task-1', 'title': 'Việc đang chọn', 'status': 'OPEN'}]
            : [],
      };
    } else {
      body = {'content': []};
    }
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
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
  testWidgets('selected todo removed on refresh returns to manual title',
      (tester) async {
    final adapter = _Adapter();
    await tester.pumpWidget(_app(adapter, const FocusScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Việc đang chọn').last);
    await tester.pumpAndSettle();
    adapter.includeTodo = false;
    final refresh = tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show();
    await tester.pumpAndSettle();
    await refresh;
    expect(tester.takeException(), isNull);
    expect(find.text('Tên phiên'), findsOneWidget);
  });

  testWidgets('retry after uncertain response uses the same operation id',
      (tester) async {
    final adapter = _Adapter()..failFirstPost = true;
    await tester.pumpWidget(_app(adapter, const FocusScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Đọc sách');
    await tester.tap(find.text('Bắt đầu'));
    await tester.pumpAndSettle();
    expect(adapter.writes, hasLength(1));
    final refresh = tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show();
    await tester.pumpAndSettle();
    await refresh;
    await tester.tap(find.text('Bắt đầu'));
    await tester.pumpAndSettle();
    expect(adapter.writes, hasLength(2));
    expect(adapter.writes[1]['operationId'], adapter.writes[0]['operationId']);
  });

  testWidgets('habit map distinguishes unknown history from rest days',
      (tester) async {
    await tester.pumpWidget(_app(
      _Adapter(),
      const HabitHeatmap(id: 'habit', from: '2026-10-01', to: '2026-10-02', revision: '1'),
    ));
    await tester.pumpAndSettle();
    expect(find.byTooltip('2026-10-01: Chưa xác minh'), findsOneWidget);
    expect(find.byTooltip('2026-10-02: Ngày nghỉ'), findsOneWidget);
    expect(find.textContaining('không đưa vào tỷ lệ'), findsOneWidget);
    expect(find.textContaining('Ngày nghỉ không ngắt chuỗi'), findsOneWidget);
  });
}
