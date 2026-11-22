import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Attaches the Bearer access token and reports 401s.
///
/// QueuedInterceptor serializes requests through the interceptor, which is what a future
/// refresh-token flow needs (refresh once, then replay the queued requests).
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({required this.tokenStorage, required this.onUnauthorized});

  final TokenStorage tokenStorage;

  /// Called when the backend rejects the token, e.g. to sign the user out.
  final void Function() onUnauthorized;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final skipAuth = options.extra['skipAuth'] == true;
    // Respect an Authorization header set explicitly by the caller (e.g. right after login).
    if (!skipAuth && !options.headers.containsKey('Authorization')) {
      final token = await tokenStorage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401 && err.requestOptions.extra['skipAuth'] != true) {
      onUnauthorized();
    }
    handler.next(err);
  }
}
