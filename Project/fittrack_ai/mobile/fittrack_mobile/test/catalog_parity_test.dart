import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fittrack_mobile/core/network/api_client.dart';
import 'package:fittrack_mobile/features/auth/auth_session.dart';
import 'package:fittrack_mobile/features/catalog/catalog_contract.dart';
import 'package:fittrack_mobile/features/catalog/catalog_screen.dart';
import 'package:fittrack_mobile/features/home/mobile_menu_controller.dart';

class FakeCatalogApi extends ApiClient {
  final queries = <Map<String, dynamic>?>[];
  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (path.endsWith('/facets')) {
      return {
        'muscleGroups': ['Chest'],
        'equipment': ['Dumbbell'],
      };
    }
    queries.add(queryParameters);
    return {
      'content': [
        {
          'id': 'one',
          'name': 'Incline Dumbbell Press',
          'active': true,
          'approvalStatus': 'APPROVED',
          'muscleGroup': 'Chest',
          'equipment': 'Dumbbell',
        },
      ],
      'totalPages': 2,
      'totalElements': 21,
    };
  }
}

void main() {
  test('Only approved active exercise can be picked', () {
    expect(
      catalogSelectableExercise({'active': true, 'approvalStatus': 'APPROVED'}),
      true,
    );
    expect(
      catalogSelectableExercise({
        'active': false,
        'approvalStatus': 'APPROVED',
      }),
      false,
    );
    expect(
      catalogSelectableExercise({'active': true, 'approvalStatus': 'PENDING'}),
      false,
    );
  });
  test('Import errors skip and updates do not select themselves', () {
    expect(
      catalogDefaultSelection({
        'number': 1,
        'errors': ['Bad'],
        'suggestedAction': 'CREATE',
      })['action'],
      'SKIP',
    );
    expect(
      catalogDefaultSelection({
        'number': 2,
        'values': {'id': 'old'},
        'suggestedAction': 'SKIP',
        'errors': [],
      })['action'],
      'SKIP',
    );
    expect(
      catalogDefaultSelection({
        'number': 3,
        'suggestedAction': 'CREATE',
        'errors': [],
      })['clearFields'],
      isEmpty,
    );
    expect(catalogCoverage({'fiber': 0, 'sodium': null}), startsWith('1/8'));
  });
  testWidgets(
    'Narrow catalog hides admin import and uses paged debounced search',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = FakeCatalogApi();
      final session = AuthSession(api);
      session.user = AuthUser.fromJson({
        'id': 'user',
        'role': 'USER',
        'fitnessEnabled': true,
      });
      final menu = MobileMenuController(api)
        ..accept({
          'version': 0,
          'modules': mobileModuleLabels.keys
              .map((key) => {'key': key, 'visible': true})
              .toList(),
        });
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiClient>.value(value: api),
            ChangeNotifierProvider<AuthSession>.value(value: session),
            ChangeNotifierProvider<MobileMenuController>.value(value: menu),
          ],
          child: const MaterialApp(home: CatalogScreen(kind: 'EXERCISE')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Incline Dumbbell Press'), findsOneWidget);
      expect(find.text('Nhập / xuất'), findsNothing);
      await tester.enterText(find.byType(TextField).first, 'nguc');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(api.queries.last?['keyword'], 'nguc');
      expect(api.queries.last?['size'], 20);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
      menu.dispose();
      api.activity.dispose();
    },
  );
}
