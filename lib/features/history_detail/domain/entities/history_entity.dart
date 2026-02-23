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
  });
}
