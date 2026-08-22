// Verifies the driver app parses the dev14 messenger payer model
// (payer / collect_at / amount_due / payment_status) and keeps the delivery fee
// distinct from the COD goods value.
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/messenger/domain/models/messenger_order.dart';
import 'package:massdrive/features/messenger/domain/models/messenger_offer.dart';

void main() {
  group('dev14 · messenger Order payer model', () {
    test('parses payer=RECIPIENT + collect_at + amount_due + payment_status', () {
      final o = MessengerOrder.fromJson(const {
        'id': 'm1',
        'payer': 'RECIPIENT',
        'collect_at': 'DELIVERY',
        'amount_due': 45.0,
        'cod_amount': 300.0,
        'payment_status': 'PENDING',
        'fare': 45.0,
      });
      expect(o.payer, 'RECIPIENT');
      expect(o.isRecipientPays, isTrue);
      expect(o.collectAt, 'DELIVERY');
      expect(o.paymentStatus, 'PENDING');
      expect(o.isFeePaid, isFalse);
      // feeDue is the delivery fee only — never the COD goods value.
      expect(o.feeDue, 45.0);
      expect(o.codAmount, 300.0);
    });

    test('payment_status PAID → isFeePaid (prepaid, nothing to collect)', () {
      final o = MessengerOrder.fromJson(const {
        'id': 'm1',
        'payer': 'SENDER',
        'payment_status': 'PAID',
        'amount_due': 25.0,
      });
      expect(o.isFeePaid, isTrue);
      expect(o.feeDue, 25.0);
    });

    test('legacy order: payer defaults SENDER, feeDue falls back to net fare', () {
      final o = MessengerOrder.fromJson(const {
        'id': 'm0',
        'fare': 60.0,
        'discount': 10.0,
      });
      expect(o.payer, 'SENDER');
      expect(o.isRecipientPays, isFalse);
      expect(o.collectAt, isNull);
      expect(o.paymentStatus, '');
      expect(o.feeDue, 50.0); // fare - discount, no amount_due
    });
  });

  group('dev14 · messenger Offer payer model', () {
    test('parses payer/collect_at/amount_due on the offer', () {
      final o = MessengerOffer.fromJson(const {
        'id': 'm1',
        'payer': 'RECIPIENT',
        'collect_at': 'DELIVERY',
        'amount_due': 40.0,
        'cod_amount': 0.0,
        'fare': 40.0,
      });
      expect(o.isRecipientPays, isTrue);
      expect(o.collectAt, 'DELIVERY');
      expect(o.feeDue, 40.0);
    });

    test('legacy offer defaults to SENDER, feeDue = fare', () {
      final o = MessengerOffer.fromJson(const {'id': 'm0', 'fare': 35.0});
      expect(o.isRecipientPays, isFalse);
      expect(o.feeDue, 35.0);
    });
  });
}
