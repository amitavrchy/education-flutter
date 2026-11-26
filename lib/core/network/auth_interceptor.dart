import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Attaches the Bearer access token. On a 401 it rotates the refresh token once and
/// replays the request; when that fails it reports the 401 so the user is signed out.
///
/// QueuedInterceptor serializes errors, so concurrent 401s trigger a single refresh.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({required this.tokenStorage, required this.onUnauthorized, this.refresh, this.retry});

  final TokenStorage tokenStorage;

  /// Called when the backend rejects the token and it can't be refreshed.
  final void Function() onUnauthorized;

  /// Rotates the session; resolves to the new access token or null.
  final Future<String?> Function()? refresh;

  /// Replays a request (the owning Dio's `fetch`).
  final Future<Response<dynamic>> Function(RequestOptions options)? retry;

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
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final unauthorized = err.response?.statusCode == 401 && options.extra['skipAuth'] != true;
    if (!unauthorized) return handler.next(err);
    if (refresh != null && retry != null && options.extra['retried'] != true) {
      final sent = options.headers['Authorization'];
      final current = await tokenStorage.readAccessToken();
      // Another queued request may already have refreshed the token.
      final token = current != null && 'Bearer $current' != sent ? current : await refresh!();
      if (token != null) {
        try {
          final replay = options.copyWith(headers: {...options.headers, 'Authorization': 'Bearer $token'}, extra: {...options.extra, 'retried': true});
          return handler.resolve(await retry!(replay));
        } on DioException catch (e) {
          return handler.next(e);
        }
      }
    }
    onUnauthorized();
    handler.next(err);
  }
}
