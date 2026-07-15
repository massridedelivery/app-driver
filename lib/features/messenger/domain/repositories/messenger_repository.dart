import 'package:massdrive/features/messenger/domain/models/messenger_order.dart';

abstract class MessengerRepository {
  /// Active messenger order, or null when there is none (404).
  Future<MessengerOrder?> getActiveOrder();

  /// Paginated DELIVERED history, newest first (SCRUM-41 §2).
  Future<({List<MessengerOrder> orders, int total})> getCompletedOrders({
    int limit,
    int offset,
  });

  /// Accept an offer. Throws with a message on 403 (COD-blocked) / 409 (taken).
  Future<void> acceptOrder(String orderId);
  Future<void> rejectOrder(String orderId);
  Future<void> arrivedOrder(String orderId);
  Future<void> pickedUpOrder(String orderId);
  Future<void> deliveredOrder(String orderId);
}
