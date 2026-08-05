class HistoryDetailEntity {
  final String id;
  final DateTime dateTime;
  final String pickupAddress;
  final String dropoffAddress;
  final double distanceKm;
  final int durationMinute;
  final double total;
  final String paymentMethod;
  final double driverNet;
  final String serviceType; // 'ride' or 'food'
  final String? restaurantName;
  final List<Map<String, dynamic>>? orderItems;

  /// Trip coordinates. Null when the backend does not supply them — the map
  /// then falls back to a default camera instead of drawing a route.
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;

  HistoryDetailEntity({
    required this.id,
    required this.dateTime,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.distanceKm,
    required this.durationMinute,
    required this.total,
    required this.paymentMethod,
    required this.driverNet,
    this.serviceType = 'ride',
    this.restaurantName,
    this.orderItems,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
  });

  bool get isFood => serviceType == 'food';

  /// True only when both endpoints of the trip are known.
  bool get hasRoute =>
      pickupLat != null &&
      pickupLng != null &&
      dropoffLat != null &&
      dropoffLng != null;
}

