/// How a parcel's fee is paid, as the offer and live cards say it:
/// "เงินสด" / "QR พร้อมเพย์" / "COD", plus who pays when it's the recipient.
/// The offer used to say "เงินสด" for every non-COD order, a PromptPay one
/// included, while the live card said "QR พร้อมเพย์".
String parcelPaymentLabel(String method, {bool recipientPays = false}) {
  final how = switch (method.toUpperCase()) {
    'COD' => 'COD',
    'PROMPTPAY' || 'QR' || 'QR_PAYMENT' => 'QR พร้อมเพย์',
    'CARD' || 'CREDIT_CARD' => 'บัตร',
    'CASH' || '' => 'เงินสด',
    final other => other,
  };
  return recipientPays ? '$how · ผู้รับจ่าย' : how;
}
