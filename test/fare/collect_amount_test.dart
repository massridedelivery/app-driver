import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/features/payment/domain/collection_amounts.dart';

/// Flows 2–4 — finishing a ride / food / messenger job: what the collect
/// (payment) screen asks the customer for.
void main() {
  group('ride → collect screen', () {
    test("uses the server's amount_due (fare + toll + waiting − promo)", () {
      expect(rideAmountToCollect(serverAmountDue: 95, fare: 82), 95);
    });

    test('a promo covering the whole fare → collect ฿0, not the fare', () {
      // ฿44 ride, ฿44 coupon: the passenger owes nothing (A07/iOS 2026-10-16).
      expect(rideAmountToCollect(serverAmountDue: 0, fare: 44), 0);
      expect(rideAmountToCollect(serverAmountDue: -3, fare: 44), 0);
    });

    test('only when the server read failed does it fall back to the fare', () {
      expect(rideAmountToCollect(serverAmountDue: null, fare: 82), 82);
    });

    test('a pushed ฿0 is collected as ฿0 on the collect screen', () {
      final a = CollectionAmounts.resolve(
        messenger: false,
        routeAmount: 0,
        jobAmountDue: 0,
        jobFare: 44,
      );
      expect(a.fee, 0);
      expect(a.cashTotal, 0);
    });

    test('the pushed amount is what the screen collects', () {
      final a = CollectionAmounts.resolve(
        messenger: false,
        routeAmount: 95,
        jobAmountDue: 70,
        jobFare: 60,
      );
      expect(a.fee, 95);
      expect(a.feeTotal, 95);
      expect(a.cashTotal, 95);
    });
  });

  group('food → collect screen (nothing pushed)', () {
    test("falls back to the live job's amount_due, then its fare", () {
      expect(
        CollectionAmounts.resolve(
          messenger: false,
          jobAmountDue: 70,
          jobFare: 60,
        ).fee,
        70,
      );
      expect(
        CollectionAmounts.resolve(
          messenger: false,
          jobAmountDue: 0,
          jobFare: 60,
        ).fee,
        60,
      );
      expect(CollectionAmounts.resolve(messenger: false, baseFare: 40).fee, 40);
    });

    test('nothing known at all is ฿0', () {
      expect(CollectionAmounts.resolve(messenger: false).fee, 0);
    });
  });

  group('messenger → collect screen', () {
    test('collects the order fee, with COD on its own line', () {
      final a = CollectionAmounts.resolve(
        messenger: true,
        routeAmount: 45,
        cod: 300,
        jobFare: 999, // a stale ride job must not leak in
      );
      expect(a.fee, 45);
      expect(a.cod, 300);
      expect(a.feeTotal, 45);
      expect(a.cashTotal, 345);
      expect(formatBaht(a.cashTotal), '฿345');
    });

    test('a ฿0 fee with COD never borrows a ride job fare', () {
      final a = CollectionAmounts.resolve(
        messenger: true,
        routeAmount: 0,
        cod: 300,
        jobAmountDue: 120,
        jobFare: 120,
      );
      expect(a.fee, 0);
      expect(a.cashTotal, 300);
    });

    test('a prepaid fee is not collected again in cash', () {
      final a = CollectionAmounts.resolve(
        messenger: true,
        prepaid: true,
        routeAmount: 45,
        cod: 300,
      );
      expect(a.fee, 0);
      expect(a.cashTotal, 300);
    });
  });

  test('tolls and others add to the fee side; negative COD is ignored', () {
    final a = CollectionAmounts.resolve(
      messenger: false,
      routeAmount: 100,
      tolls: 25,
      others: 10.5,
      cod: -5,
    );
    expect(a.feeTotal, 135.5);
    expect(a.cod, 0);
    expect(a.cashTotal, 135.5);
    expect(formatBahtNumber(a.feeTotal), '135.50');
  });
}
