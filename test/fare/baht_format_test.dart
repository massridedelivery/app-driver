import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/utils/baht.dart';

/// The one money formatter every screen uses.
void main() {
  group('formatBaht', () {
    test('whole baht stays whole, with a thousands separator', () {
      expect(formatBaht(2), '฿2');
      expect(formatBaht(1200), '฿1,200');
      expect(formatBaht(50000), '฿50,000');
      expect(formatBaht(0), '฿0');
    });

    test('satang are kept, never rounded away or truncated', () {
      expect(formatBaht(0.4), '฿0.40');
      expect(formatBaht(82.83), '฿82.83');
      expect(formatBaht(99.6), '฿99.60');
      expect(formatBaht(1234.5), '฿1,234.50');
    });

    test('rounds to the satang (no float noise)', () {
      expect(formatBaht(0.1 + 0.2), '฿0.30');
      expect(formatBaht(10.004), '฿10');
    });

    test('drops the sign — callers choose how to show a debit', () {
      expect(formatBaht(-0.4), '฿0.40');
      expect(formatBaht(-13), '฿13');
    });
  });

  test('formatBahtNumber is the same figure without the symbol', () {
    expect(formatBahtNumber(45), '45');
    expect(formatBahtNumber(82.83), '82.83');
    expect(formatBahtNumber(1500), '1,500');
  });

  group('formatSignedBaht', () {
    test('negative shows a leading minus before the symbol', () {
      expect(formatSignedBaht(-13), '-฿13');
      expect(formatSignedBaht(-0.4), '-฿0.40');
    });

    test('positive is plain unless asked for a plus', () {
      expect(formatSignedBaht(2), '฿2');
      expect(formatSignedBaht(2, plus: true), '+฿2');
    });

    test('anything that rounds to zero is ฿0 — never ฿-0 or +฿0', () {
      expect(formatSignedBaht(0), '฿0');
      expect(formatSignedBaht(-0.0), '฿0');
      expect(formatSignedBaht(-0.004), '฿0');
      expect(formatSignedBaht(0.004, plus: true), '฿0');
    });
  });
}
