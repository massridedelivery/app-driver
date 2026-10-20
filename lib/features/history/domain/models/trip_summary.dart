/// What the trip list (`GET /api/driver/earnings/trips`) knows about a job:
/// its vehicle type and the backend-resolved whole-baht net.
class TripSummary {
  const TripSummary({
    this.vehicleTypeName,
    this.driverNet,
    this.distanceKm,
    this.paymentMethod,
    this.discount,
    this.customerPaid,
    this.cashCollected,
    this.walletCredit,
  });

  /// `driver_info.vehicle_type_name` (or a top-level `vehicle_type_name`).
  final String? vehicleTypeName;

  /// `driver_net`; null until the trip settles.
  final int? driverNet;

  /// `distance_km` and `payment_method` (CASH / PROMPTPAY / …) for the
  /// receipt card's sub-line.
  final double? distanceKm;
  final String? paymentMethod;

  /// How the customer paid, for the receipt's "ลูกค้าชำระ" block (shown when
  /// there's a promo). All from the backend — never derived here:
  /// `discount` (platform-funded promo), `customer_paid` (what the customer
  /// paid), `cash_collected` (cash the driver took), `wallet_credit` (what
  /// the trip moved in the driver's wallet; negative = owed back).
  final double? discount;
  final double? customerPaid;
  final double? cashCollected;
  final double? walletCredit;
}

/// job id → [TripSummary] from the trip list response.
Map<String, TripSummary> tripSummariesByJob(Object? response) {
  final list = response is Map ? response['data'] : null;
  if (list is! List) return const {};
  final out = <String, TripSummary>{};
  for (final t in list.whereType<Map>()) {
    final id = t['id']?.toString();
    if (id == null || id.isEmpty) continue;
    final info = t['driver_info'];
    final name =
        (info is Map ? info['vehicle_type_name'] : null) ??
        t['vehicle_type_name'];
    final net = t['driver_net'];
    final km = t['distance_km'];
    final pay = t['payment_method']?.toString().trim();
    double? n(String k) => t[k] is num ? (t[k] as num).toDouble() : null;
    out[id] = TripSummary(
      vehicleTypeName: name?.toString(),
      driverNet: net is num ? net.round() : null,
      distanceKm: km is num ? km.toDouble() : null,
      paymentMethod: (pay == null || pay.isEmpty) ? null : pay,
      discount: n('discount'),
      customerPaid: n('customer_paid'),
      cashCollected: n('cash_collected'),
      walletCredit: n('wallet_credit'),
    );
  }
  return out;
}

/// job id → vehicle type name (jobs without one are left out).
Map<String, String> vehicleTypesByJob(Object? response) => {
  for (final e in tripSummariesByJob(response).entries)
    if (e.value.vehicleTypeName != null) e.key: e.value.vehicleTypeName!,
};
