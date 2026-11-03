/// A cost the driver paid for the customer and adds to the bill (BE #66):
/// a ride's toll, or another cost (parking, a gate) on a ride or a parcel.
/// The backend takes each as the job's total — not an amount to add — and
/// folds it into amount_due.
enum ExtraCharge { toll, other }

/// The most either charge can be, per job (BE).
const double maxExtraCharge = 500;

/// Why [amount] / [note] can't be sent, or null when they can. Mirrors the
/// backend's rules so the driver hears it before the round trip.
String? extraChargeError(
  ExtraCharge kind, {
  required double? amount,
  String note = '',
}) {
  if (amount == null || amount < 0) return 'กรุณาใส่จำนวนเงิน';
  if (amount > maxExtraCharge) return 'ใส่ได้สูงสุด ฿500';
  // The toll endpoint takes 1–500: a toll can be set, not cleared.
  if (kind == ExtraCharge.toll && amount == 0) {
    return 'ค่าทางด่วนต้องมากกว่า ฿0';
  }
  if (kind == ExtraCharge.other && amount > 0 && note.trim().isEmpty) {
    return 'กรุณาระบุว่าเป็นค่าอะไร';
  }
  return null;
}

/// "ค่าทางด่วน" / "ค่าอื่นๆ (ค่าจอดรถ)" — a bill line's label.
String extraChargeLabel(ExtraCharge kind, {String? note}) => switch (kind) {
  ExtraCharge.toll => 'ค่าทางด่วน',
  ExtraCharge.other =>
    (note == null || note.trim().isEmpty) ? 'ค่าอื่นๆ' : 'ค่าอื่นๆ (${note.trim()})',
};
