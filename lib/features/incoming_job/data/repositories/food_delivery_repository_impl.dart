import 'package:injectable/injectable.dart';
import '../../data/sources/food_delivery_api_service.dart';
import '../../domain/repositories/food_delivery_repository.dart';

@LazySingleton(as: FoodDeliveryRepository)
class FoodDeliveryRepositoryImpl implements FoodDeliveryRepository {
  final FoodDeliveryApiService _apiService;

  FoodDeliveryRepositoryImpl(this._apiService);

  @override
  Future<void> acceptOrder(String orderId) async {
    await _apiService.acceptOrder(orderId);
  }

  @override
  Future<void> pickedUpOrder(String orderId) async {
    await _apiService.pickedUpOrder(orderId);
  }

  @override
  Future<void> deliveredOrder(String orderId) async {
    await _apiService.deliveredOrder(orderId);
  }

  @override
  Future<List<dynamic>> getActiveOrders() async {
    final response = await _apiService.getActiveOrders();
    return response.data ?? [];
  }
}
