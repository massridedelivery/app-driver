import 'package:massdrive/core/utils/baht.dart';

/// The backend's `driver_earnings` on a ride or parcel:
/// `{commission_rate: 0.2, commission: 13, driver_net: 50}`. Whole baht,
/// commission + driver_net == fare, worked out on the full fare (a platform
/// promo is not taken from the driver). The app never computes these itself:
/// without the block nothing is shown.
class DriverEarnings {
  const DriverEarnings({
    required this.driverNet,
    this.commission,
    this.commissionRate,
  });

  final double driverNet;
  final double? commission;

  /// A fraction: 0.2 is 20 %.
  final double? commissionRate;

  /// Null unless [raw] is a map with a numeric `driver_net`.
  static DriverEarnings? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final net = _num(raw['driver_net']);
    if (net == null) return null;
    return DriverEarnings(
      driverNet: net,
      commission: _num(raw['commission']),
      commissionRate: _num(raw['commission_rate']),
    );
  }

  Map<String, dynamic> toJson() => {
    'driver_net': driverNet,
    'commission': commission,
    'commission_rate': commissionRate,
  };

  /// "ค่าคอม 20% (฿13)", "ค่าคอม ฿13" without a rate, null without a
  /// commission.
  String? get commissionLine {
    final c = commission;
    if (c == null) return null;
    final pct = commissionPercent(commissionRate);
    return pct == null
        ? 'ค่าคอม ${formatBaht(c)}'
        : 'ค่าคอม $pct (${formatBaht(c)})';
  }
}

/// 0.2 → "20%", 0.125 → "12.5%"; null for a missing or negative rate.
String? commissionPercent(double? rate) {
  if (rate == null || rate < 0) return null;
  final tenths = (rate * 1000).round();
  return tenths % 10 == 0 ? '${tenths ~/ 10}%' : '${tenths / 10}%';
}

double? _num(Object? v) =>
    v is num ? v.toDouble() : (v is String ? double.tryParse(v.trim()) : null);
