import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fittrack_mobile/core/network/api_client.dart';
import 'package:fittrack_mobile/features/fitness/fitness_screen.dart';

class _HistoryApi extends ApiClient {
  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (path.endsWith('/weekly-volume')) {
      return {'muscleGroups': [], 'totalWorkingSets': 0, 'totalVolume': 0};
    }
    if (path.endsWith('/diary')) return {'meals': []};
    if (path.endsWith('/convenience')) return <String, dynamic>{};
    return {'content': [], 'totalPages': 0, 'totalElements': 0};
  }
}

void main() {
  testWidgets(
    'nutrition tab can be globally hidden and reopened without ticker crash',
    (tester) async {
      final api = _HistoryApi();
      final show = ValueNotifier(true);
      await tester.pumpWidget(
        Provider<ApiClient>.value(
          value: api,
          child: MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: show,
                builder: (_, visible, _) =>
                    FitnessScreen(showNutrition: visible),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nhật ký ăn'), findsOneWidget);
      show.value = false;
      await tester.pumpAndSettle();
      expect(find.text('Nhật ký ăn'), findsNothing);
      show.value = true;
      await tester.pumpAndSettle();
      expect(find.text('Nhật ký ăn'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      show.dispose();
      api.activity.dispose();
    },
  );
}
