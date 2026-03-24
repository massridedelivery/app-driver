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
    if (error.response != null && error.response?.data != null) {
      return ApiException.fromResponse(error.response?.data);
    }
    return ApiException(0, message: error.toString());
  }

  @override
  String toString() {
    return 'ApiException(code: $code, status: $status, message: $message)';
  }
}
