import 'package:dio/dio.dart';

/// Turns a [DioException] into an exception carrying the backend's own reason.
class ApiError {
  const ApiError._();

  /// Human-readable reason from the backend, preferring the contract's
  /// `message` field, falling back to legacy `error`.
  static String? serverMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return (data['message'] ?? data['error'])?.toString();
    }
    return null;
  }

  /// Rethrow with the best message available.
  static Never surface(DioException e, String fallbackMessage) {
    throw Exception(serverMessage(e) ?? fallbackMessage);
  }
}
