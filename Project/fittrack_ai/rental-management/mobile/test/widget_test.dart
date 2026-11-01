import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  test('định dạng tiền và trạng thái', () {
    expect(money(1234567), '1.234.567 đ');
    expect(label('PENDING'), 'Chờ xác nhận');
    expect(label(null), 'Chưa phân bổ');
  });
}
