import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/features/messenger/domain/models/messenger_offer.dart';
import 'package:massdrive/features/messenger/domain/models/messenger_order.dart';

/// Flow 5 — messenger: offer → live order → collect.
void main() {
  group('offer', () {
    test('fee due is the server amount_due, else the fare', () {
      final withDue = MessengerOffer.fromJson({'fare': 50, 'amount_due': 40});
      expect(withDue.feeDue, 40);
      expect(MessengerOffer.fromJson({'fare': 35}).feeDue, 35);
    });

    test('fare and COD display with satang', () {
      final o = MessengerOffer.fromJson({'fare': 42.5, 'cod_amount': 300});
      expect(formatBahtNumber(o.fare), '42.50');
      expect(formatBaht(o.codAmount), '฿300');
    });
  });

  group('order built from the offer (active-detail fetch unavailable)', () {
    final offer = MessengerOffer.fromJson({
      'id': 'MSG-1',
      'fare': 60,
      'amount_due': 45,
      'cod_amount': 300,
      'payer': 'RECIPIENT',
      'collect_at': 'DELIVERY',
      'payment_method': 'CASH',
    });

    test('keeps the server fee and who/where it is collected', () {
      final order = MessengerOrder.fromOffer(offer);
      expect(order.id, 'MSG-1');
      expect(order.amountDue, 45);
      expect(order.feeDue, 45); // used to fall back to fare (60)
      expect(order.payer, 'RECIPIENT');
      expect(order.isRecipientPays, isTrue);
      expect(order.collectAt, 'DELIVERY');
      expect(order.codAmount, 300);
      expect(order.fare, 60);
    });
  });

  group('order fee due', () {
    test('amount_due wins and is never negative', () {
      expect(
        MessengerOrder.fromJson({'fare': 60, 'amount_due': 45}).feeDue,
        45,
      );
      expect(MessengerOrder.fromJson({'fare': 60, 'amount_due': 0}).feeDue, 0);
      expect(MessengerOrder.fromJson({'fare': 60, 'amount_due': -5}).feeDue, 0);
    });

    test('legacy orders collect fare − discount, floored at 0', () {
      expect(MessengerOrder.fromJson({'fare': 60, 'discount': 10}).feeDue, 50);
      expect(MessengerOrder.fromJson({'fare': 20, 'discount': 30}).feeDue, 0);
    });

    test('COD is never folded into the fee', () {
      final o = MessengerOrder.fromJson({
        'fare': 60,
        'amount_due': 45,
        'cod_amount': 300,
      });
      expect(o.feeDue, 45);
      expect(o.codAmount, 300);
    });

    test('a PAID order is flagged so the fee is not collected again', () {
      final o = MessengerOrder.fromJson({
        'fare': 60,
        'amount_due': 0,
        'payment_status': 'PAID',
      });
      expect(o.isFeePaid, isTrue);
      expect(o.feeDue, 0);
    });
  });
}
