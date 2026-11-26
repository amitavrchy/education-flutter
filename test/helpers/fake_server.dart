import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shikkhaai_mobile/core/network/api_client.dart';

/// Tiny in-memory backend for API-mode tests: GET returns stored lists, PUT {items}
/// replaces them, POST appends; every request is recorded.
class FakeServer implements HttpClientAdapter {
  FakeServer([Map<String, List<Map<String, dynamic>>>? data]) : data = data ?? {};

  final Map<String, List<Map<String, dynamic>>> data;
  final List<String> calls = [];

  /// Canned replies keyed by `'METHOD /path'`; they win over [data].
  final Map<String, Object?> responses = {};
  final Map<String, Object?> lastBody = {};

  late final ApiClient client = ApiClient(Dio()..httpClientAdapter = this);

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? body, Future<void>? cancel) async {
    calls.add('${o.method} ${o.path}');
    lastBody[o.path] = o.data;
    Object? out;
    final key = '${o.method} ${o.path}';
    if (responses.containsKey(key)) {
      return ResponseBody.fromString(jsonEncode({'success': true, 'data': responses[key]}), 200, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });
    }
    switch (o.method) {
      case 'GET':
        out = data[o.path] ?? <Object>[];
      case 'PUT':
        data[o.path] = [for (final x in (o.data as Map)['items'] as List) (x as Map).cast<String, dynamic>()];
        out = data[o.path];
      case 'POST':
        out = o.data;
      default:
        out = null;
    }
    return ResponseBody.fromString(jsonEncode({'success': true, 'data': out}), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}
