import 'history_item_model.dart';
import 'trip_summary.dart';

export 'trip_summary.dart';

/// The trip-history list shows only what belongs to a trip — fares,
/// commissions — each tagged with the job's vehicle type for its icon.
/// Top-ups / adjustments / withdrawals are left out: they have their own
/// history screens.
List<HistoryItemModel> tripRows(
  Iterable<HistoryItemModel> raw,
  Map<String, TripSummary> trips,
) => raw.where((i) => i.isTripEntry).map((i) {
  final t = trips[i.jobId];
  return i.withTrip(t);
}).toList();

/// Card line label for a history row: the fare / commission by type, the
/// row's own (already Thai) title otherwise.
String historyLineLabel(HistoryItemModel i) =>
    switch (i.rawType?.toUpperCase()) {
      'FARE_PAYMENT' => 'ค่าโดยสาร',
      'COMMISSION_DEDUCTION' => 'หักค่าคอมมิชชัน',
      'MARKETING_EXPENSE' => 'ส่วนลด (บริษัทออกให้)',
      _ => i.title,
    };

/// `marketing_expense`: the platform-funded promo on a job. Part of the fare
/// the company paid — already in the fare and driver_net, and shown in the
/// receipt's "ลูกค้าชำระ" block — so it is not a money line of its own.
bool isPromoDiscountRow(HistoryItemModel i) =>
    i.rawType?.toUpperCase() == 'MARKETING_EXPENSE';

/// The job's money lines for its card: everything but the promo row.
List<HistoryItemModel> jobCardLines(Iterable<HistoryItemModel> rows) =>
    jobCardOrder(rows.where((i) => !isPromoDiscountRow(i)));

/// A job's rows in card order: fare first, then the commission, then the rest.
List<HistoryItemModel> jobCardOrder(Iterable<HistoryItemModel> rows) {
  int rank(HistoryItemModel i) => switch (i.rawType?.toUpperCase()) {
    'FARE_PAYMENT' => 0,
    'COMMISSION_DEDUCTION' => 1,
    _ => 2,
  };
  return [...rows]..sort((a, b) => rank(a).compareTo(rank(b)));
}

/// Thai label for a trip's payment method on the receipt card.
String paymentMethodLabel(String? raw) => switch (raw?.toUpperCase()) {
  'CASH' => 'เงินสด',
  'PROMPTPAY' || 'QR' || 'QR_PAYMENT' => 'QR',
  'CARD' || 'CREDIT_CARD' => 'บัตร',
  null || '' => '',
  final other => other,
};
