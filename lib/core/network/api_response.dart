/// Pagination info sent with list responses.
class PaginationMeta {
  const PaginationMeta({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) => PaginationMeta(
    page: json['page'] as int,
    pageSize: json['pageSize'] as int,
    total: json['total'] as int,
    totalPages: json['totalPages'] as int,
  );

  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
}

/// The backend's success envelope: `{ success: true, data, meta? }`.
class ApiResponse<T> {
  const ApiResponse({required this.data, this.meta, this.message});

  /// [parseData] converts the raw `data` field into [T].
  factory ApiResponse.fromJson(Object? json, T Function(Object? data) parseData) {
    if (json is! Map<String, dynamic> || json['success'] != true) {
      throw const FormatException('Response is not a ShikkhaAI success envelope');
    }
    final meta = json['meta'];
    return ApiResponse(
      data: parseData(json['data']),
      meta: meta is Map<String, dynamic> ? PaginationMeta.fromJson(meta) : null,
      message: json['message'] as String?,
    );
  }

  final T data;
  final PaginationMeta? meta;
  final String? message;
}
