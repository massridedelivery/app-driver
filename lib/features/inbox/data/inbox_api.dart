import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/inbox/domain/inbox_message.dart';

/// The driver's own inbox (กล่องข้อความ). Every call needs the session; the
/// backend only ever touches the caller's rows.
class InboxApi {
  InboxApi(this._dio);

  final Dio _dio;

  Future<InboxPage> list({int limit = 20, int offset = 0}) async {
    final res = await _dio.get(
      Endpoints.notifications,
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return InboxPage.fromJson(res.data);
  }

  Future<void> markRead(String id) =>
      _dio.patch(Endpoints.notificationRead(id));

  /// The backend's 404 `{"error": "not found"}` (already gone, or not this
  /// driver's) means deleted. Any other 404 — e.g. a backend without the
  /// endpoint yet — is a failure, so the row comes back.
  Future<void> delete(String id) async {
    try {
      await _dio.delete(Endpoints.notification(id));
    } on DioException catch (e) {
      if (!isRowNotFound(e.response?.statusCode, e.response?.data)) rethrow;
    }
  }

  Future<void> deleteAll() => _dio.delete(Endpoints.notifications);

  Future<void> readAll() => _dio.patch(Endpoints.notificationsReadAll);

  /// PDPA consent for marketing campaigns. Jobs, chat, calls and account
  /// pushes don't depend on it.
  Future<bool> marketingOptIn() async {
    final res = await _dio.get(Endpoints.notificationPrefs);
    return _optIn(res.data) ?? true;
  }

  Future<bool> setMarketingOptIn(bool value) async {
    final res = await _dio.patch(
      Endpoints.notificationPrefs,
      data: {'marketing_opt_in': value},
    );
    return _optIn(res.data) ?? value;
  }

  static bool? _optIn(Object? data) =>
      data is Map && data['marketing_opt_in'] is bool
      ? data['marketing_opt_in'] as bool
      : null;
}

/// The inbox's own "no such row" answer, as opposed to a route the backend
/// doesn't serve.
bool isRowNotFound(int? status, Object? body) =>
    status == 404 && body is Map && body['error'] == 'not found';

final inboxApiProvider = Provider<InboxApi>((ref) => InboxApi(getIt<Dio>()));
