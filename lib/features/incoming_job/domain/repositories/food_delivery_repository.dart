abstract class FoodDeliveryRepository {
  Future<void> acceptOrder(String orderId);
  Future<void> pickedUpOrder(String orderId);
  Future<void> deliveredOrder(String orderId);
  Future<List<dynamic>> getActiveOrders();
}
