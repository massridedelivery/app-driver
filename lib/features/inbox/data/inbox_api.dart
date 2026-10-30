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

  /// A 404 (already gone, or not this driver's) is not an error: it's deleted.
  Future<void> delete(String id) async {
    try {
      await _dio.delete(Endpoints.notification(id));
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
    }
  }

  Future<void> deleteAll() => _dio.delete(Endpoints.notifications);

  Future<void> readAll() => _dio.patch(Endpoints.notificationsReadAll);
}

final inboxApiProvider = Provider<InboxApi>((ref) => InboxApi(getIt<Dio>()));
