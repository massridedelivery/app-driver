/// What a ride hands to the collect screen: the backend's `amount_due` (fare +
/// en-route tolls/waiting) when it is real, else the fare — never ฿0 for an
/// unpaid ride (SCRUM-86 §6).
double rideAmountToCollect({double? amountDue, required double fare}) =>
    (amountDue ?? 0) > 0 ? amountDue! : fare;

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
  /// fare. Ride/food fall back to the live job's amount_due → fare → baseFare,
  /// the first that is > 0.
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
    } else {
      for (final v in [routeAmount, jobAmountDue, jobFare, baseFare]) {
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
