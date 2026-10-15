/// What a ride collects from the passenger. [serverAmountDue] is the
/// backend's `amount_due` from a fresh active-job read (fare + toll + waiting
/// − promo) and is used as-is — ฿0 included, since a promo can cover the whole
/// fare. Only when that read failed does it fall back to the quoted fare.
///
/// (The offer kept in memory always carries amount_due 0, so it must never be
/// passed here — that's why the old rule refused ฿0 and over-collected
/// fully-discounted rides.)
double rideAmountToCollect({double? serverAmountDue, required double fare}) {
  if (serverAmountDue == null) return fare;
  return serverAmountDue < 0 ? 0 : serverAmountDue;
}

/// The money on the collect (payment) screen.
class CollectionAmounts {
  const CollectionAmounts({
    required this.fee,
    this.tolls = 0,
    this.others = 0,
    this.cod = 0,
  });

  /// Ride fare / delivery fee still to collect. 0 when already prepaid.
  final double fee;
  final double tolls;
  final double others;

  /// Messenger goods value collected on delivery — a separate debt from the
  /// fee, shown on its own line.
  final double cod;

  /// What the fee side comes to (the QR / "ทั้งหมด" figure).
  double get feeTotal => fee + tolls + others;

  /// Cash the driver physically takes at the door: fee side + COD.
  double get cashTotal => feeTotal + cod;

  /// [intentAmount] is the live QR intent's amount — the server's figure,
  /// which includes waiting fees, so it wins when present.
  /// [routeAmount] is what the caller pushed. A messenger order always sends
  /// its own fee (0 when there is none), so it never borrows a ride job's
  /// fare. A ride's pushed amount is the server's amount_due and is used as-is;
  /// food (nothing pushed) falls back to the live job's amount_due → fare →
  /// baseFare, the first that is > 0.
  factory CollectionAmounts.resolve({
    required bool messenger,
    bool prepaid = false,
    double? intentAmount,
    double? routeAmount,
    double? jobAmountDue,
    double? jobFare,
    double baseFare = 0,
    double tolls = 0,
    double others = 0,
    double? cod,
  }) {
    double fee = 0;
    if (prepaid) {
      fee = 0;
    } else if ((intentAmount ?? 0) > 0) {
      // The live QR's own amount (fare + waiting fee) is what gets charged.
      fee = intentAmount!;
    } else if (messenger) {
      fee = (routeAmount ?? 0) > 0 ? routeAmount! : 0;
    } else if (routeAmount != null) {
      // Ride: the live screen pushes the server's amount_due — trust it, ฿0
      // included (a promo covering the whole fare).
      fee = routeAmount < 0 ? 0 : routeAmount;
    } else {
      for (final v in [jobAmountDue, jobFare, baseFare]) {
        if (v != null && v > 0) {
          fee = v;
          break;
        }
      }
    }
    return CollectionAmounts(
      fee: fee,
      tolls: tolls,
      others: others,
      cod: (cod ?? 0) > 0 ? cod! : 0,
    );
  }
}
