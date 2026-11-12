/// Food orders as the backend sends them (BE v1.6.26), read into what the
/// app's job screens use.
library;

/// The driver's stage on a food order.
enum FoodLiveState { headingToRestaurant, atRestaurant, delivering }

/// The restaurant is still cooking: the driver already holds the order
/// (GET /api/food/driver/orders/active returns it from here on), but it
/// can't be picked up until READY_FOR_PICKUP.
const foodPreparingStatuses = {'RESTAURANT_ACCEPTED', 'PREPARING'};

/// The order ended without the driver delivering it: close its screen.
const foodEndedStatuses = {
  'CANCELLED',
  'FAILED_DELIVERY',
  'FAILED_DISPATCH',
  'EXTERNALLY_DISPATCHED',
  'RESTAURANT_REJECTED',
};

bool isRestaurantPreparing(String? status) =>
    foodPreparingStatuses.contains(status?.toUpperCase());

/// Where the live screen resumes for an order [status]: once picked up the
/// driver is on the way to the customer; before that, to the restaurant.
FoodLiveState foodLiveStateFor(String? status) =>
    status?.toUpperCase() == 'DRIVER_PICKED_UP'
    ? FoodLiveState.delivering
    : FoodLiveState.headingToRestaurant;

/// A food order (the offer frame, a WS order, or an active order) as
/// IncomingJobModel JSON. The backend names the stops after the restaurant
/// and the delivery point; ride-shaped keys, when present, win.
Map<String, dynamic> foodOrderAsJobJson(Map<String, dynamic> order) {
  final json = Map<String, dynamic>.from(order);
  double? numOf(String k) => (order[k] as num?)?.toDouble();
  String? text(String k) {
    final v = order[k]?.toString().trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  json['pickup_lat'] ??= numOf('restaurant_lat') ?? 0.0;
  json['pickup_lng'] ??= numOf('restaurant_lng') ?? 0.0;
  json['dropoff_lat'] ??= numOf('delivery_lat') ?? 0.0;
  json['dropoff_lng'] ??= numOf('delivery_lng') ?? 0.0;
  json['pickup_address'] ??=
      text('restaurant_address') ?? text('restaurant_name') ?? '';
  json['dropoff_address'] ??= text('delivery_address') ?? '';
  // The driver earns on the delivery fee, plus any part the platform waived
  // for the customer.
  json['fare'] ??=
      (numOf('delivery_fee') ?? 0) + (numOf('delivery_fee_waived') ?? 0);
  json['payment_method'] ??= '';
  json['order_items'] ??= order['items'] ?? const [];
  json['subtotal'] ??= numOf('food_total') ?? 0.0;
  json['dropoff_distance_km'] ??= numOf('fulfillment_distance_km') ?? 0.0;
  json['service_type'] ??= 'MassFood';
  return json;
}

/// The driver's current order from GET /api/food/driver/orders/active
/// (`{batch, orders: [...]}`; a bare order or a list also read), as job JSON
/// plus its status. Null when there's none.
({Map<String, dynamic> json, String? status})? activeFoodOrderFrom(
  dynamic body,
) {
  Object? order = body;
  if (body is Map && body['orders'] is List) order = body['orders'];
  if (body is Map && body['order'] is Map) order = body['order'];
  if (order is List) order = order.isEmpty ? null : order.first;
  if (order is! Map || order['id'] == null) return null;
  final map = Map<String, dynamic>.from(order);
  return (json: foodOrderAsJobJson(map), status: map['status']?.toString());
}

/// A food status frame about one order (`driver_assigned`, `order_ready`,
/// `status_updated`, `order_cancelled`, …): `{type, order_id, status,
/// order}`. Null for frames without an order id.
({String type, String orderId, String? status, Map<String, dynamic>? order})?
foodFrameOf(String type, Map<String, dynamic> raw, Map<String, dynamic>? data) {
  Object? read(String k) => raw[k] ?? data?[k];
  final order = read('order');
  final orderMap = order is Map ? Map<String, dynamic>.from(order) : null;
  final id = (read('order_id') ?? orderMap?['id'])?.toString();
  if (id == null || id.isEmpty) return null;
  final status = (read('status') ?? orderMap?['status'])?.toString();
  return (type: type, orderId: id, status: status, order: orderMap);
}

/// Whether a food frame ends the order for the driver: `order_cancelled`
/// (cancelled, or ended without delivery), `externally_dispatched`, or a
/// back-office `status_updated` to such a status.
bool isFoodOrderEndedFrame(String type, String? status) {
  switch (type) {
    case 'order_cancelled':
    case 'externally_dispatched':
      return true;
    case 'status_updated':
      return foodEndedStatuses.contains(status?.toUpperCase());
  }
  return false;
}

/// What the driver reads when a food order ends under them.
String foodOrderEndedMessage(String? status) => switch (status?.toUpperCase()) {
  'FAILED_DELIVERY' => 'ออเดอร์นี้ปิดแล้ว (ส่งไม่สำเร็จ)',
  'EXTERNALLY_DISPATCHED' => 'ออเดอร์นี้ส่งต่อให้ผู้ส่งรายอื่นแล้ว',
  'RESTAURANT_REJECTED' => 'ร้านยกเลิกออเดอร์นี้',
  _ => 'ออเดอร์นี้ถูกยกเลิกแล้ว',
};
