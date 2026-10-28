import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fittrack_mobile/core/network/api_client.dart';
import 'package:fittrack_mobile/features/nutrition_planning/meal_planning_screen.dart';

class PlanningApi extends ApiClient {
  final writes = <Map<String, dynamic>>[];
  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (path.endsWith('/groceries')) return {'version': 2, 'items': []};
    if (path.endsWith('/summary'))
      return {
        'plannedMealCount': 31,
        'totals': {
          'calories': 6200,
          'protein': 310,
          'carbs': 620,
          'fat': 124,
          'knownMicronutrientValues': 0,
          'possibleMicronutrientValues': 248,
        },
      };
    return {
      'totalPages': 1,
      'content': [
        {
          'id': 'planned',
          'version': 4,
          'date': '2020-01-06',
          'mealType': 'BREAKFAST',
          'name': 'Bữa kiểm tra',
          'items': [],
          'totals': {
            'calories': 0,
            'protein': 0,
            'carbs': 0,
            'fat': 0,
            'knownMicronutrientValues': 0,
            'possibleMicronutrientValues': 8,
          },
        },
      ],
    };
  }

  @override
  Future<dynamic> post(String path, {Object? data}) async {
    writes.add({'path': path, 'data': data});
    return {'mealLogId': 'actual'};
  }
}

void main() {
  test(
    'planning week starts on Monday, including Sunday and month boundary',
    () {
      expect(planningDate(planningMonday(DateTime(2026, 11, 1))), '2026-10-26');
    },
  );
  testWidgets(
    'narrow meal planner viewing and canceling consumption do not post actual meals',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = PlanningApi();
      await tester.pumpWidget(
        Provider<ApiClient>.value(
          value: api,
          child: const MaterialApp(home: MealPlanningScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bữa kiểm tra'), findsOneWidget);
      expect(api.writes, isEmpty);
      await tester.ensureVisible(find.text('Đã ăn → nhật ký'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đã ăn → nhật ký'));
      await tester.pumpAndSettle();
      expect(find.textContaining('có thể khác dự kiến'), findsOneWidget);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(api.writes, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'confirming consumption carries version and explicit log endpoint',
    (tester) async {
      final api = PlanningApi();
      await tester.pumpWidget(
        Provider<ApiClient>.value(
          value: api,
          child: const MaterialApp(home: MealPlanningScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Đã ăn → nhật ký'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đã ăn → nhật ký'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
      await tester.pumpAndSettle();
      expect(
        api.writes.single['path'],
        '/nutrition/planning/meals/planned/log',
      );
      expect(api.writes.single['data'], {'version': 4});
      expect(tester.takeException(), isNull);
    },
  );
}
