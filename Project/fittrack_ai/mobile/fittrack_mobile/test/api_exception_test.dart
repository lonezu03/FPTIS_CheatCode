import 'package:dio/dio.dart';
import 'package:fittrack_mobile/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('friendlyErrorMessage', () {
    test('extracts the backend message without dumping the response', () {
      final error = DioException.badResponse(
        statusCode: 409,
        requestOptions: RequestOptions(path: '/finance/transactions'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/finance/transactions'),
          statusCode: 409,
          data: {
            'error': 'Conflict',
            'message': 'Số dư không đủ để thực hiện giao dịch',
            'status': 409,
          },
        ),
      );

      expect(
        friendlyErrorMessage(error),
        'Số dư không đủ để thực hiện giao dịch',
      );
    });

    test('translates a generic server response', () {
      expect(
        friendlyErrorMessage({'error': 'Internal Server Error', 'status': 500}),
        'Máy chủ gặp sự cố. Vui lòng thử lại sau.',
      );
    });

    test('renders validation values without the response map syntax', () {
      expect(
        friendlyErrorMessage({
          'errors': {
            'title': ['Tiêu đề không được để trống'],
            'amount': ['Số tiền phải lớn hơn 0'],
          },
        }),
        'Tiêu đề không được để trống\nSố tiền phải lớn hơn 0',
      );
    });

    test('keeps the request id for production log correlation', () {
      const error = ApiException(
        'Dịch vụ đang tạm gián đoạn.',
        statusCode: 503,
        requestId: 'request-123',
      );

      expect(
        friendlyErrorMessage(error),
        'Dịch vụ đang tạm gián đoạn.\nMã yêu cầu: request-123',
      );
    });
  });
}
