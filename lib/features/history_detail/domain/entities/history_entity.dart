class HistoryDetailEntity {
  final String id;
  final DateTime dateTime;
  final String pickupAddress;
  final String dropoffAddress;
  final double distanceKm;

  /// Accepted → completed, in minutes. Null when the trip has no completion
  /// time, so the screen shows "-" instead of a made-up figure.
  final int? durationMinute;
  final double total;
  final String paymentMethod;
  final double driverNet;

  /// Settled earnings in whole baht, resolved by the backend
  /// (gross_fare − commission == driver_net). All null until the trip settles.
  final int? grossFare;
  final int? commission;
  final int? settledNet;
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
    this.grossFare,
    this.commission,
    this.settledNet,
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
