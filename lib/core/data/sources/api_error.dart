import 'package:dio/dio.dart';

/// Turns a [DioException] into an exception carrying the backend's own reason.
class ApiError {
  const ApiError._();

  /// Human-readable reason from the backend, already in the phone's language
  /// (Accept-Language): `message`, else `error`. A bare code such as
  /// `job_taken` is not a sentence and is skipped.
  static String? serverMessage(DioException e) => messageFromBody(e.response?.data);

  /// [serverMessage] for a response body.
  static String? messageFromBody(Object? data) {
    if (data is! Map) return null;
    for (final key in const ['message', 'error']) {
      final text = data[key]?.toString().trim();
      if (text != null && text.isNotEmpty && !_code.hasMatch(text)) {
        return text;
      }
    }
    return null;
  }

  static final _code = RegExp(r'^[a-z0-9_.]+$');

  /// Rethrow with the best message available.
  static Never surface(DioException e, String fallbackMessage) {
    throw Exception(serverMessage(e) ?? fallbackMessage);
  }
}
