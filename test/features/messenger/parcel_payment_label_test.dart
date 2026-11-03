import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/messenger/domain/parcel_payment_label.dart';

void main() {
  // The offer card used to say "เงินสด" for every order that wasn't COD, a
  // PromptPay one included, while the live card said "QR พร้อมเพย์".
  test('the offer and the live card name the same payment method', () {
    expect(parcelPaymentLabel('PROMPTPAY'), 'QR พร้อมเพย์');
    expect(parcelPaymentLabel('promptpay'), 'QR พร้อมเพย์');
    expect(parcelPaymentLabel('CASH'), 'เงินสด');
    expect(parcelPaymentLabel(''), 'เงินสด');
    expect(parcelPaymentLabel('COD'), 'COD');
  });

  test('says when the recipient pays', () {
    expect(
      parcelPaymentLabel('PROMPTPAY', recipientPays: true),
      'QR พร้อมเพย์ · ผู้รับจ่าย',
    );
    expect(parcelPaymentLabel('CASH'), 'เงินสด');
  });
}
