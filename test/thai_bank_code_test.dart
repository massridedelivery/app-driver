import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/constants/thai_banks.dart';

void main() {
  test('KBank is 004, not Bangkok Bank 002', () {
    expect(thaiBankCode('ธนาคารกสิกรไทย'), '004');
    expect(thaiBankCode('kbank'), '004'); // legacy stored value
    expect(thaiBankCode('Kasikorn Bank'), '004');
    expect(thaiBankCode('กสิกรไทย (KBank)'), '004'); // old free-text entry
    expect(thaiBankCode('ธนาคารกรุงเทพ'), '002');
  });

  test('every listed bank has its own Bank of Thailand code', () {
    final codes = kThaiBanks.map((b) => b.botCode).toList();
    expect(codes.toSet().length, kThaiBanks.length);
    expect(codes.every((c) => RegExp(r'^\d{3}$').hasMatch(c)), isTrue);
    expect(thaiBankCode('ธนาคารทีเอ็มบีธนชาต'), '011');
    expect(thaiBankCode('ธนาคารออมสิน'), '030');
    expect(thaiBankCode('ธนาคารไทยพาณิชย์'), '014');
    expect(thaiBankCode('ธนาคารกรุงศรีอยุธยา'), '025');
    expect(thaiBankCode('ธนาคารกรุงไทย'), '006');
  });

  test('unknown banks return null instead of a wrong default', () {
    expect(thaiBankCode('Some Bank'), isNull);
    expect(thaiBankCode(''), isNull);
    expect(thaiBankCode(null), isNull);
  });
}
