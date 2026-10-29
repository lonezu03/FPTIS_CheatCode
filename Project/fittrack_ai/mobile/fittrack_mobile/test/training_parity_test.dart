import 'package:dio/dio.dart';
import 'package:fittrack_mobile/core/network/api_client.dart';
import 'package:fittrack_mobile/features/auth/auth_session.dart';
import 'package:fittrack_mobile/features/fitness/live_workout_sheet.dart';
import 'package:fittrack_mobile/features/fitness/training_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  test('volume excludes warmup, unfinished and unknown completion', () {
    expect(
      trainingVolume([
        {
          'sets': [
            {'weight': 10, 'reps': 10, 'setType': 'NORMAL', 'completed': true},
            {'weight': 20, 'reps': 10, 'setType': 'WARMUP', 'completed': true},
            {'weight': 30, 'reps': 10, 'setType': 'NORMAL', 'completed': false},
            {'weight': 30, 'reps': 10, 'setType': 'NORMAL'},
          ],
        },
      ]),
      100,
    );
  });

  test('plan payload preserves version/prescription, normalizes visible order and strips response IDs', () {
    final payload = trainingPlanPayload({
      'id': 'p',
      'version': 4,
      'name': 'Plan',
      'days': [
        {
          'id': 'd',
          'name': 'Day',
          'dayOrder': 10,
          'exercises': [
            {
              'id': 'pe',
              'exerciseId': 'e',
              'exerciseOrder': 9,
              'targetSets': 3,
              'targetReps': 10,
              'targetWeight': 12.5,
              'targetRir': 2,
              'restSeconds': 120,
              'minReps': 8,
              'maxReps': 12,
              'coachingNote': 'Chậm',
              'groupKey': 'A',
              'groupType': 'SUPERSET',
              'groupRounds': 3,
              'betweenExerciseRestSeconds': 15,
              'betweenRoundRestSeconds': 90,
            },
          ],
        },
      ],
    });
    expect(payload['id'], isNull);
    expect(payload['version'], 4);
    final day = (payload['days'] as List).first as Map;
    expect(day['dayOrder'], 1);
    final exercise = (day['exercises'] as List).first as Map;
    expect(exercise['exerciseOrder'], 1);
    expect(exercise['id'], isNull);
    expect(exercise['restSeconds'], 120);
    expect(exercise['minReps'], 8);
    expect(exercise['coachingNote'], 'Chậm');
    expect(exercise['groupKey'], 'A');
    expect(exercise['groupType'], 'SUPERSET');
    expect(exercise['groupRounds'], 3);
    expect(exercise['betweenExerciseRestSeconds'], 15);
    expect(exercise['betweenRoundRestSeconds'], 90);
  });

  Future<void> mount(WidgetTester tester, ApiClient api, Widget child) async {
    final auth = AuthSession(api);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: api),
          ChangeNotifierProvider<AuthSession>.value(value: auth),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  ApiClient mockApi(List<RequestOptions> writes) {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.method != 'GET') {
            writes.add(options);
          }
          dynamic data = [];
          if (options.path == '/exercises/page') {
            data = {
              'content': [
                {'id': 'active', 'name': 'Active exercise'},
              ],
            };
          }
          if (options.path.contains('/intelligence')) {
            data = <String, dynamic>{};
          }
          if (options.path.endsWith('/alternatives')) {
            data = [
              {'exercise': {'id': 'replacement', 'name': 'Máy thay thế', 'equipment': 'Máy'}, 'preference': 'NORMAL'},
            ];
          }
          if (options.method == 'PUT' || options.method == 'POST') {
            data = {'id': 'saved', 'newPersonalRecords': []};
          }
          handler.resolve(
            Response(requestOptions: options, statusCode: 200, data: data),
          );
        },
      ),
    );
    return ApiClient(dio: dio);
  }

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('đổi bài giữ hiệp đã hoàn thành và lưu nguồn thay thế', (tester) async {
    // Give the workout editor enough vertical space for its fixed footer;
    // the separate 360px test below covers the compact layout.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final writes = <RequestOptions>[];
    await mount(tester, mockApi(writes), const LiveWorkoutSheet(planDay: {
      'name': 'Ngày tập',
      'exercises': [{
        'exerciseId': 'plan-ex', 'exerciseName': 'Bài ban đầu',
        'targetSets': 2, 'targetReps': 10, 'targetWeight': 25.0,
      }],
    }));
    final first = find.byType(Checkbox).first;
    await tester.ensureVisible(first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(first);
    await tester.pump();
    final change = find.text('Đổi bài tương đương');
    await tester.ensureVisible(change);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(change);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.text('Máy thay thế'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.text('Đổi bài'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Bài ban đầu'), findsOneWidget);
    expect(find.text('Máy thay thế'), findsOneWidget);
    final checkboxes = find.byType(Checkbox);
    expect(tester.widget<Checkbox>(checkboxes.first).value, isTrue);
    expect(tester.widget<Checkbox>(checkboxes.last).value, isFalse);
    await tester.ensureVisible(checkboxes.last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(checkboxes.last);
    await tester.pump();
    final save = find.text('Hoàn thành buổi tập');
    await tester.ensureVisible(save);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(save);
    await tester.pump(const Duration(milliseconds: 200));
    final sets = (writes.single.data as Map)['sets'] as List;
    expect(sets, hasLength(2));
    expect(sets[0]['exerciseId'], 'plan-ex');
    expect(sets[0]['weight'], 25.0);
    expect(sets[1]['exerciseId'], 'replacement');
    expect(sets[1]['weight'], 0);
    expect(sets[1]['originalExerciseId'], 'plan-ex');
    expect(sets[1]['replacementKind'], 'ALTERNATIVE');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'plan start opens incomplete live sets without POST/generate at 360px',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final writes = <RequestOptions>[];
      await mount(
        tester,
        mockApi(writes),
        const LiveWorkoutSheet(
          planDay: {
            'name': 'Ngày đẩy',
            'exercises': [
              {
                'exerciseId': 'plan-ex',
                'exerciseName': 'Máy đẩy ngực',
                'targetSets': 2,
                'targetReps': 10,
                'restSeconds': 120,
                'minReps': 8,
                'maxReps': 12,
                'coachingNote': 'Giữ vai ổn định',
              },
            ],
          },
        ),
      );
      expect(find.text('Buổi tập trực tiếp'), findsOneWidget);
      expect(find.text('Máy đẩy ngực'), findsOneWidget);
      expect(
        tester
            .widgetList<Checkbox>(find.byType(Checkbox))
            .every((e) => e.value == false),
        isTrue,
      );
      expect(writes, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'scheduled completion posts one occurrence only and preserves group',
    (tester) async {
      final writes = <RequestOptions>[];
      await mount(
        tester,
        mockApi(writes),
        const LiveWorkoutSheet(
          appointmentId: 'occurrence',
          planDay: {
            'name': 'Ngày đẩy',
            'exercises': [
              {
                'exerciseId': 'plan-ex',
                'exerciseName': 'Máy đẩy ngực',
                'targetSets': 1,
                'targetReps': 8,
                'groupKey': 'A',
                'groupType': 'SUPERSET',
                'groupRounds': 1,
                'betweenExerciseRestSeconds': 15,
                'betweenRoundRestSeconds': 90,
              },
            ],
          },
        ),
      );
      expect(writes, isEmpty);
      final checkbox = find.byType(Checkbox).first;
      await tester.ensureVisible(checkbox);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(checkbox);
      await tester.pump();
      await tester.tap(find.text('Hoàn thành buổi tập'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(writes, hasLength(1));
      expect(
        writes.single.path,
        '/workout-plans/appointments/occurrence/complete',
      );
      final data = writes.single.data as Map;
      expect(((data['session'] as Map)['sets'] as List).first['groupKey'], 'A');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('full historical edit keeps archived ID/name and each set rest', (
    tester,
  ) async {
    final writes = <RequestOptions>[];
    await mount(
      tester,
      mockApi(writes),
      const LiveWorkoutSheet(
        initialSession: {
          'id': 'history',
          'sessionDate': '2026-10-24',
          'durationMinutes': 55,
          'note': 'Buổi cũ',
          'sets': [
            {
              'exerciseId': 'archived',
              'exerciseName': 'Bài đã lưu trữ',
              'exerciseOrder': 1,
              'setNumber': 1,
              'weight': 20.0,
              'reps': 10,
              'rir': 2,
              'restSeconds': 75,
              'setType': 'NORMAL',
              'completed': true,
            },
            {
              'exerciseId': 'archived',
              'exerciseName': 'Bài đã lưu trữ',
              'exerciseOrder': 1,
              'setNumber': 2,
              'weight': 22.0,
              'reps': 8,
              'rir': 1,
              'restSeconds': 150,
              'setType': 'NORMAL',
              'completed': true,
            },
          ],
        },
      ),
    );
    expect(find.text('Bài đã lưu trữ'), findsOneWidget);
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(writes, hasLength(1));
    expect(writes.single.path, '/workouts/sessions/history/details');
    expect(writes.single.method, 'PUT');
    final data = writes.single.data as Map;
    expect(data['durationMinutes'], 55);
    expect(data['sessionDate'], '2026-10-24');
    expect((data['sets'] as List).map((e) => e['exerciseId']), [
      'archived',
      'archived',
    ]);
    expect((data['sets'] as List).map((e) => e['restSeconds']), [75, 150]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
