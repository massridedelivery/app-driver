import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/features/messenger/data/sources/messenger_api_service.dart';
import 'package:massdrive/features/messenger/domain/models/messenger_order.dart';
import 'package:massdrive/features/messenger/domain/repositories/messenger_repository.dart';

@LazySingleton(as: MessengerRepository)
class MessengerRepositoryImpl implements MessengerRepository {
  final MessengerApiService _api;

  MessengerRepositoryImpl(this._api);

  /// Backend error bodies are `{ "message": … }` or `{ "error": … }`.
  String _message(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      final m = data['message'] ?? data['error'];
      if (m != null) return m.toString();
    }
    return fallback;
  }

  MessengerOrder? _parse(dynamic data) {
    if (data is Map<String, dynamic>) {
      final body =
          data['order'] is Map<String, dynamic> ? data['order'] : data;
      return MessengerOrder.fromJson(body as Map<String, dynamic>);
    }
    return null;
  }

  @override
  Future<MessengerOrder?> getActiveOrder() async {
    try {
      final res = await _api.getActiveOrder();
      if (res.statusCode == 200) return _parse(res.data);
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null; // no active order
      throw Exception(_message(e, 'Failed to fetch active order'));
    }
  }

  @override
  Future<({List<MessengerOrder> orders, int total})> getCompletedOrders({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final res = await _api.getCompletedOrders(limit: limit, offset: offset);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final list = (data['orders'] as List?) ?? const [];
        final orders = list
            .whereType<Map<String, dynamic>>()
            .map(MessengerOrder.fromJson)
            .toList();
        final total = (data['total'] as num?)?.toInt() ?? orders.length;
        return (orders: orders, total: total);
      }
      return (orders: <MessengerOrder>[], total: 0);
    } on DioException catch (e) {
      throw Exception(_message(e, 'Failed to fetch completed orders'));
    }
  }

  @override
  Future<void> acceptOrder(String orderId) async {
    try {
      await _api.acceptOrder(orderId);
    } on DioException catch (e) {
      // 403 → COD-blocked, 409 → already taken (SCRUM-41 §4).
      throw Exception(_message(e, 'Failed to accept order'));
    }
  }

  @override
  Future<void> rejectOrder(String orderId) async {
    try {
      await _api.rejectOrder(orderId);
    } on DioException catch (e) {
      throw Exception(_message(e, 'Failed to reject order'));
    }
  }

  @override
  Future<void> arrivedOrder(String orderId) async {
    try {
      await _api.arrivedOrder(orderId);
    } on DioException catch (e) {
      throw Exception(_message(e, 'Failed to mark arrived'));
    }
  }

  @override
  Future<void> pickedUpOrder(String orderId) async {
    try {
      await _api.pickedUpOrder(orderId);
    } on DioException catch (e) {
      throw Exception(_message(e, 'Failed to mark picked up'));
    }
  }

  @override
  Future<void> deliveredOrder(String orderId) async {
    try {
      await _api.deliveredOrder(orderId);
    } on DioException catch (e) {
      throw Exception(_message(e, 'Failed to mark delivered'));
    }
  }
}
