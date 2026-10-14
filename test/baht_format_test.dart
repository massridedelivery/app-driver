import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/utils/baht.dart';

void main() {
  test('whole baht stays whole, satang are kept', () {
    expect(formatBaht(1200), '฿1,200');
    expect(formatBaht(2), '฿2');
    expect(formatBaht(0.4), '฿0.40');
    expect(formatBaht(-0.4), '฿0.40');
    expect(formatBaht(82.83), '฿82.83');
    expect(formatBaht(0), '฿0');
  });
}
