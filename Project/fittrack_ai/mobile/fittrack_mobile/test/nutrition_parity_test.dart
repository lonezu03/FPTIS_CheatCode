import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fittrack_mobile/core/network/api_client.dart';
import 'package:fittrack_mobile/features/fitness/nutrition_contract.dart';
import 'package:fittrack_mobile/features/fitness/nutrition_diary_tab.dart';

class _NutritionApi extends ApiClient {
  final calls = <String>[];
  final writes = <Map<String, dynamic>>[];
  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    calls.add('$path:${queryParameters?['keyword'] ?? ''}');
    if (path == '/nutrition/diary') return {'meals': [], 'status': 'UNLOGGED'};
    if (path == '/nutrition/convenience') return <String, dynamic>{};
    if (path == '/nutrition/foods/page') {
      final milk = queryParameters?['keyword'] == 'sua';
      return {
        'content': [
          milk
              ? {
                  'id': 'milk',
                  'name': 'Sữa',
                  'unit': '200ml',
                  'servingSizeGrams': 200,
                }
              : {
                  'id': 'chicken',
                  'name': 'Gà',
                  'unit': '100g',
                  'servingSizeGrams': 100,
                },
        ],
        'totalPages': 1,
      };
    }
    throw StateError('Unexpected GET $path');
  }

  @override
  Future<dynamic> post(String path, {Object? data}) async {
    writes.add(Map<String, dynamic>.from(data as Map));
    return {};
  }
}

class _SnapshotApi extends _NutritionApi {
  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (path == '/nutrition/diary') {
      calls.add(path);
      return {
        'status': 'PARTIAL',
        'meals': [
          {
            'id': 'meal',
            'mealType': 'BREAKFAST',
            'items': [
              {
                'foodId': 'food',
                'foodName': 'Tên món lịch sử',
                'foodUnit': '1 chén',
                'foodSourceName': 'Nhãn cũ',
                'quantity': 1,
                'calories': 120,
                'sodium': null,
              },
            ],
          },
        ],
      };
    }
    return super.get(path, queryParameters: queryParameters);
  }
}

void main() {
  testWidgets(
    'diary displays historical food snapshot without resolving current catalog',
    (tester) async {
      final api = _SnapshotApi();
      await tester.pumpWidget(
        Provider<ApiClient>.value(
          value: api,
          child: const MaterialApp(home: Scaffold(body: NutritionDiaryTab())),
        ),
      );
      await tester.pumpAndSettle();
      final name = find.text('Tên món lịch sử');
      await tester.scrollUntilVisible(
        name,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(name);
      await tester.pumpAndSettle();
      expect(find.text('Khẩu phần gốc: 1 chén'), findsOneWidget);
      expect(find.text('Nguồn: Nhãn cũ'), findsOneWidget);
      expect(find.text('Natri (mg): Chưa biết'), findsOneWidget);
      expect(api.calls.any((e) => e.contains('/foods')), isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      api.activity.dispose();
    },
  );
  test('no gram/ml inference and photo liquid falls back to serving', () {
    final milk = {'unit': '200ml', 'servingSizeGrams': 200};
    expect(nutritionUnits(milk), ['SERVING', 'ML']);
    expect(photoServing(milk, 150), {'unit': 'SERVING', 'amount': 1.0});
    expect(nutritionItemPayload('milk', milk, 100, 'ML')['quantity'], .5);
    expect(
      () => nutritionItemPayload('milk', milk, 100, 'GRAM'),
      throwsFormatException,
    );
    expect(
      () => nutritionItemPayload('milk', milk, double.nan, 'SERVING'),
      throwsFormatException,
    );
    expect(nutritionUnits({'unit': 'cái'}), ['SERVING']);
  });

  testWidgets(
    'server search retains selected food across pages/search and saves units',
    (tester) async {
      final api = _NutritionApi();
      await tester.pumpWidget(
        Provider<ApiClient>.value(
          value: api,
          child: const MaterialApp(home: Scaffold(body: NutritionDiaryTab())),
        ),
      );
      await tester.pumpAndSettle();
      final add = find.byKey(const ValueKey('meal-add-BREAKFAST'));
      await tester.scrollUntilVisible(
        add,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(api.calls.any((e) => e.startsWith('/nutrition/foods:')), isFalse);
      await tester.tap(find.text('Gà'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Tìm thực phẩm'),
        'sua',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Gà'), findsOneWidget);
      expect(find.text('Sữa'), findsOneWidget);
      await tester.tap(find.text('Sữa'));
      await tester.pumpAndSettle();
      final save = find.text('Lưu 2 món');
      await tester.scrollUntilVisible(
        save,
        250,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('meal-editor-list')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect((api.writes.single['items'] as List).map((e) => e['foodId']), [
        'chicken',
        'milk',
      ]);
      expect(tester.takeException(), isNull);
      api.activity.dispose();
    },
  );
}
