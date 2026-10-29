import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_mobile/features/personal_tracking/monthly_report_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('requires exactly requested sections and current permission', () {
    final report = {
      'sections': ['TRAINING', 'FINANCE'],
    };
    expect(monthlyReportSectionsAllowed(report, {'TRAINING'}), isFalse);
    expect(
      monthlyReportSectionsAllowed(
        report,
        {'TRAINING', 'FINANCE'},
        requested: {'TRAINING'},
      ),
      isFalse,
    );
    expect(
      monthlyReportSectionsAllowed(
        report,
        {'TRAINING', 'FINANCE'},
        requested: {'TRAINING', 'FINANCE'},
      ),
      isTrue,
    );
    expect(
      monthlyReportSectionsAllowed(
        {
          'sections': ['TRAINING', 'TRAINING'],
        },
        {'TRAINING'},
      ),
      isFalse,
    );
  });

  test('builds a local PDF with Vietnamese text and missing values', () async {
    final bytes = await buildMonthlyReportPdf({
      'sections': ['NUTRITION'],
      'month': '2026-10-01',
      'through': '2026-10-29',
      'nutrition': {
        'qualifyingDays': 0,
        'observedDays': 3,
        'coveragePercent': 0,
        'averageCalories': null,
        'averageProtein': null,
        'averageCarbs': null,
        'averageFat': null,
      },
      'disclaimer': 'Dữ liệu cá nhân',
    });
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });
}
