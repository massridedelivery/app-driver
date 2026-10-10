class ApiException implements Exception {
  final int code;
  final String? status;
  final String? message;
  final Map<String, dynamic>? data;

  const ApiException(this.code, {this.status, this.message, this.data});

  factory ApiException.fromResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      return ApiException(
        data['code'] is int ? data['code'] as int : 0,
        status: data['status'] as String?,
        message: data['message'] as String?,
        data: data['data'] as Map<String, dynamic>?,
      );
    }
    return const ApiException(0, message: 'Invalid error format');
  }

  factory ApiException.fromDioError(dynamic error) {
    // Keep the HTTP status: the driver API replies with a bare
    // `{"error": "..."}` body (no `code`/`message`), so without this a 400 and
    // a 409 were indistinguishable (code 0, message null).
    final int? statusCode = error.response?.statusCode as int?;
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      return ApiException(
        data['code'] is int ? data['code'] as int : (statusCode ?? 0),
        status: data['status'] as String?,
        message: (data['message'] ?? data['error'])?.toString(),
        data: data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : null,
      );
    }
    if (data != null) return ApiException.fromResponse(data);
    return ApiException(statusCode ?? 0, message: error.toString());
  }

  @override
  String toString() {
    return 'ApiException(code: $code, status: $status, message: $message)';
  }
}
