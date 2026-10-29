import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fittrack_mobile/features/nutrition_planning/pantry_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'unresolved keys survive reopening and stay scoped to the owner',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final key = PantryOperationKey(owner: 'user-1', scope: 'create');
      final first = await key.forBody({'foodId': 'food-1', 'quantity': 1});
      expect(await key.forBody({'foodId': 'food-1', 'quantity': 1}), first);
      expect(
        await key.forBody({'foodId': 'food-1', 'quantity': 2}),
        isNot(first),
      );
      // Returning to an unresolved payload after changing the form must not
      // create a second batch if its previous request timed out after commit.
      final reopened = PantryOperationKey(owner: 'user-1', scope: 'create');
      expect(
        await reopened.forBody({'foodId': 'food-1', 'quantity': 1}),
        first,
      );
      final otherUser = PantryOperationKey(owner: 'user-2', scope: 'create');
      expect(
        await otherUser.forBody({'foodId': 'food-1', 'quantity': 1}),
        isNot(first),
      );
      await reopened.complete({'foodId': 'food-1', 'quantity': 1});
      expect(
        await key.forBody({'foodId': 'food-1', 'quantity': 1}),
        isNot(first),
      );
    },
  );

  test(
    'dates retain calendar day and supported units match server contract',
    () {
      expect(pantryDate(DateTime(2026, 1, 3)), '2026-01-03');
      expect(pantryUnits.keys.toSet(), {'SERVING', 'GRAM', 'ML'});
    },
  );
}
