import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/features/income/domain/models/payout.dart';
import 'package:massdrive/features/income/domain/models/topup.dart';
import 'package:massdrive/features/payment/domain/collection_amounts.dart';

/// Backend dev88 contract: payout wht/net, slip resubmit window, QR amount.
void main() {
  group('payout record wht_amount / net_amount', () {
    test('shown as recorded by the backend', () {
      final r = PayoutRecord.fromJson({
        'id': 'p1',
        'amount': 150,
        'status': 'completed',
        'wht_amount': 1.5,
        'net_amount': 148.5,
      });
      expect(r.whtAmount, 1.5);
      expect(r.netAmount, 148.5);
      expect(formatBaht(r.netAmount!), '฿148.50');
    });

    test('old payloads without them give null (no FE recompute)', () {
      final r = PayoutRecord.fromJson({
        'id': 'p',
        'amount': 200,
        'status': 'failed',
      });
      expect(r.whtAmount, isNull);
      expect(r.netAmount, isNull);
    });
  });

  group('slip resubmit', () {
    TopupRequest slip(Map<String, dynamic> extra) => TopupRequest.fromJson({
      'id': 'r',
      'amount': 100,
      'status': 'rejected',
      'created_at': '2026-06-17T16:15:00Z',
      ...extra,
    });

    test("the backend's can_resubmit decides", () {
      expect(slip({'can_resubmit': true}).canResubmit(), isTrue);
      expect(
        slip({
          'can_resubmit': false,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        }).canResubmit(),
        isFalse,
      );
    });

    test('intent_expires_at is read as local time', () {
      final s = slip({'intent_expires_at': '2026-10-15T08:00:00Z'});
      expect(s.intentExpiresAt, DateTime.utc(2026, 10, 15, 8).toLocal());
    });

    test('without the flag it falls back to the 24h rule', () {
      expect(slip({}).canResubmit(), isFalse); // June slip, long expired
    });
  });

  group('QR amount', () {
    test("the live intent's amount (incl. waiting fee) wins", () {
      final a = CollectionAmounts.resolve(
        messenger: false,
        intentAmount: 97,
        routeAmount: 85,
      );
      expect(a.fee, 97);
      expect(a.feeTotal, 97);
    });

    test('no intent yet → the pushed amount', () {
      expect(
        CollectionAmounts.resolve(messenger: false, routeAmount: 85).fee,
        85,
      );
    });

    test('a prepaid order ignores any intent amount', () {
      expect(
        CollectionAmounts.resolve(
          messenger: true,
          prepaid: true,
          intentAmount: 45,
        ).fee,
        0,
      );
    });
  });
}
