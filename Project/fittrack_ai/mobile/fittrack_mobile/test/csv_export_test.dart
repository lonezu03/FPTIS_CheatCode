import 'package:fittrack_mobile/core/storage/csv_export.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'CSV preserves Vietnamese, quotes, numeric values and neutralizes formulas',
    () {
      expect(
        encodeCsv(
          ['Tên', 'Số'],
          [
            ['=SUM(1,2)', -8],
            ['Sáo "Đô"', null],
          ],
        ),
        '\uFEFF"Tên","Số"\r\n"\'=SUM(1,2)","-8"\r\n"Sáo ""Đô""",""\r\n',
      );
    },
  );
}
