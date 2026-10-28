import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_mobile/features/fitness/workout_group_editor.dart';

void main() {
  testWidgets('group editor fits narrow screen and clears every group field', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final value = <String, dynamic>{
      'groupKey': 'A',
      'groupType': 'SUPERSET',
      'groupRounds': 3,
      'betweenExerciseRestSeconds': 15,
      'betweenRoundRestSeconds': 90,
    };
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) => WorkoutGroupEditor(
                value: value,
                onChanged: () => setState(() {}),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Nghỉ giữa vòng (giây)'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tập riêng').last);
    await tester.pumpAndSettle();
    for (final key in trainingGroupKeys) expect(value[key], isNull);
    expect(tester.takeException(), isNull);
  });
}
