import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';

/// Driver-side messenger REST (SCRUM-41 §2). Uses plain Dio so callers can read
/// the HTTP status (403 COD-blocked, 409 already taken) off the DioException.
abstract class MessengerApiService {
  Future<Response> getActiveOrder();
  Future<Response> getCompletedOrders({int limit, int offset});
  Future<Response> getOffer(String orderId);
  Future<Response> acceptOrder(String orderId);
  Future<Response> rejectOrder(String orderId);
  Future<Response> arrivedOrder(String orderId);
  Future<Response> pickedUpOrder(String orderId);
  Future<Response> deliveredOrder(String orderId);
}

@LazySingleton(as: MessengerApiService)
class MessengerApiServiceImpl implements MessengerApiService {
  final Dio _dio;

  MessengerApiServiceImpl(this._dio);

  String _path(String template, String orderId) =>
      template.replaceAll(':id', orderId);

  @override
  Future<Response> getActiveOrder() =>
      _dio.get(Endpoints.messengerDriverActive);

  @override
  Future<Response> getCompletedOrders({int limit = 20, int offset = 0}) =>
      _dio.get(
        Endpoints.messengerDriverCompleted,
        queryParameters: {'limit': limit, 'offset': offset},
      );

  @override
  Future<Response> getOffer(String orderId) =>
      _dio.get(_path(Endpoints.messengerDriverOffer, orderId));

  @override
  Future<Response> acceptOrder(String orderId) =>
      _dio.post(_path(Endpoints.messengerDriverAccept, orderId));

  @override
  Future<Response> rejectOrder(String orderId) =>
      _dio.post(_path(Endpoints.messengerDriverReject, orderId));

  @override
  Future<Response> arrivedOrder(String orderId) =>
      _dio.post(_path(Endpoints.messengerDriverArrived, orderId));

  @override
  Future<Response> pickedUpOrder(String orderId) =>
      _dio.post(_path(Endpoints.messengerDriverPickedUp, orderId));

  @override
  Future<Response> deliveredOrder(String orderId) =>
      _dio.post(_path(Endpoints.messengerDriverDelivered, orderId));
}
