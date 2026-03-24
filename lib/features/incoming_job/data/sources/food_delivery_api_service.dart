import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';

abstract class FoodDeliveryApiService {
  Future<Response> acceptOrder(String orderId);
  Future<Response> pickedUpOrder(String orderId);
  Future<Response> deliveredOrder(String orderId);
  Future<Response<List<dynamic>>> getActiveOrders();
}

@LazySingleton(as: FoodDeliveryApiService)
class FoodDeliveryApiServiceImpl implements FoodDeliveryApiService {
  final Dio _dio;

  FoodDeliveryApiServiceImpl(this._dio);

  @override
  Future<Response> acceptOrder(String orderId) async {
    final endpoint = Endpoints.foodDriverOrdersAccept.replaceAll(
      ':id',
      orderId,
    );
    return await _dio.post(endpoint);
  }

  @override
  Future<Response> pickedUpOrder(String orderId) async {
    final endpoint = Endpoints.foodDriverOrdersPickedUp.replaceAll(
      ':id',
      orderId,
    );
    return await _dio.post(endpoint);
  }

  @override
  Future<Response> deliveredOrder(String orderId) async {
    final endpoint = Endpoints.foodDriverOrdersDelivered.replaceAll(
      ':id',
      orderId,
    );
    return await _dio.post(endpoint);
  }

  @override
  Future<Response<List<dynamic>>> getActiveOrders() async {
    return await _dio.get<List<dynamic>>(Endpoints.foodDriverOrdersActive);
  }
}
