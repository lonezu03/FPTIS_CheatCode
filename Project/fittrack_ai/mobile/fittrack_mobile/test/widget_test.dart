import 'package:fittrack_mobile/core/theme/app_theme.dart';
import 'package:fittrack_mobile/core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('trạng thái rỗng hiển thị tiếng Việt', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: EmptyView(
            icon: Icons.notifications_none,
            title: 'Không có thông báo',
            subtitle: 'Thông báo mới sẽ xuất hiện tại đây.',
          ),
        ),
      ),
    );

    expect(find.text('Không có thông báo'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
  });
}
