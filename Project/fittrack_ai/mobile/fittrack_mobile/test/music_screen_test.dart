import 'package:dio/dio.dart';
import 'package:fittrack_mobile/core/network/api_client.dart';
import 'package:fittrack_mobile/features/music/music_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _MusicApi extends ApiClient {
  final saved = <Map<String, dynamic>>[];
  Map<String, dynamic>? historyQuery;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    if (path == '/music/summary') {
      return {
        'streakDays': 1,
        'todayMinutes': 15,
        'weekMinutes': 15,
        'sessionsCount': 1,
        'weekByDay': <dynamic>[],
        'bestBpmByExercise': <dynamic>[],
        'totalMinutesByInstrument': {'GUITAR': 15},
      };
    }
    if (path == '/music/sessions') {
      historyQuery = queryParameters;
      return {'content': <dynamic>[], 'totalPages': 0};
    }
    throw StateError('Unexpected GET $path');
  }

  @override
  Future<dynamic> post(String path, {Object? data}) async {
    expect(path, '/music/sessions');
    saved.add(Map<String, dynamic>.from(data as Map));
    return {'id': 'session'};
  }
}

void main() {
  test('music CSV escapes formulas, multiline notes and quotes', () {
    final csv = encodeMusicCsv([
      {
        'practicedOn': '2026-11-28',
        'instrument': 'GUITAR',
        'exerciseKey': 'guitar-spider',
        'minutes': 15,
        'note': '=A1\n"tập"',
      },
    ]);
    expect(csv, startsWith('\ufeff'));
    expect(csv, contains('"Ghi-ta","Spider 1-2-3-4","15","","\'=A1\n""tập"""'));
  });

  testWidgets('practice journal submits the existing music API contract', (
    tester,
  ) async {
    final api = _MusicApi();
    await tester.pumpWidget(
      Provider<ApiClient>.value(
        value: api,
        child: const MaterialApp(home: MusicScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.text('Ghi buổi luyện tập');
    await tester.scrollUntilVisible(button, 150);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu buổi tập'));
    await tester.pumpAndSettle();
    expect(api.saved, hasLength(1));
    expect(api.saved.single, containsPair('instrument', 'GUITAR'));
    expect(api.saved.single, containsPair('exerciseKey', 'guitar-warmup'));
    expect(api.saved.single, containsPair('minutes', 15));
    expect(api.saved.single['practicedOn'], matches(r'^\d{4}-\d{2}-\d{2}$'));
    expect(api.historyQuery, containsPair('page', 0));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    api.activity.dispose();
    api.dio.close();
  });
}
