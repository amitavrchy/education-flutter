import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/core/network/api_exception.dart';
import 'package:shikkhaai_mobile/core/network/api_response.dart';

DioException _badResponse(int status, Object? data) {
  final options = RequestOptions(path: '/test');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  group('ApiResponse', () {
    test('parses the success envelope with pagination', () {
      final response = ApiResponse<List<String>>.fromJson(
        {
          'success': true,
          'data': ['a', 'b'],
          'meta': {'page': 1, 'pageSize': 20, 'total': 2, 'totalPages': 1},
        },
        (data) => (data! as List<dynamic>).cast<String>(),
      );
      expect(response.data, ['a', 'b']);
      expect(response.meta?.total, 2);
    });

    test('rejects anything that is not a success envelope', () {
      expect(
        () => ApiResponse<Object?>.fromJson({'success': false}, (data) => data),
        throwsFormatException,
      );
    });
  });

  group('ApiException', () {
    test('reads the backend error envelope, including field errors', () {
      final error = ApiException.fromDioException(
        _badResponse(400, {
          'success': false,
          'statusCode': 400,
          'code': 'VALIDATION_FAILED',
          'message': 'Validation failed',
          'errors': {
            'password': ['too short'],
          },
          'requestId': 'req-1',
        }),
      );
      expect(error.statusCode, 400);
      expect(error.code, 'VALIDATION_FAILED');
      expect(error.fieldErrors['password'], ['too short']);
      expect(error.requestId, 'req-1');
    });

    test('flags 401 as unauthorized', () {
      final error = ApiException.fromDioException(
        _badResponse(401, {'statusCode': 401, 'code': 'UNAUTHORIZED', 'message': 'Missing access token'}),
      );
      expect(error.isUnauthorized, isTrue);
    });

    test('maps connection failures to a network error', () {
      final error = ApiException.fromDioException(
        DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionError,
        ),
      );
      expect(error.isNetworkError, isTrue);
      expect(error.statusCode, 0);
    });
  });
}
