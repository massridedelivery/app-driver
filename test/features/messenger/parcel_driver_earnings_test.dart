import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/history/domain/models/trip_history_rows.dart';
import 'package:massdrive/features/history/domain/models/trip_summary.dart';
import 'package:massdrive/features/history_detail/presentation/controllers/history_detail_provider.dart';
import 'package:massdrive/features/incoming_job/domain/models/driver_earnings.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/messenger/domain/models/messenger_offer.dart';
import 'package:massdrive/features/messenger/domain/models/messenger_order.dart';

const _earnings = {'commission_rate': 0.2, 'commission': 13, 'driver_net': 50};

void main() {
  group('DriverEarnings', () {
    test('reads the backend block', () {
      final e = DriverEarnings.fromJson(_earnings)!;
      expect(e.driverNet, 50);
      expect(e.commission, 13);
      expect(e.commissionRate, 0.2);
      expect(e.commissionLine, 'ค่าคอม 20% (฿13)');
    });

    test('a per-driver rate reads as its own %', () {
      final e = DriverEarnings.fromJson({
        'commission_rate': 0.1,
        'commission': 6,
        'driver_net': 57,
      })!;
      expect(e.commissionLine, 'ค่าคอม 10% (฿6)');
    });

    test('no block, or no driver_net, is nothing — never derived', () {
      expect(DriverEarnings.fromJson(null), isNull);
      expect(DriverEarnings.fromJson({'commission': 13}), isNull);
      expect(DriverEarnings.fromJson('x'), isNull);
    });

    test('commission without a rate drops the %', () {
      final e = DriverEarnings.fromJson({'commission': 13, 'driver_net': 50})!;
      expect(e.commissionLine, 'ค่าคอม ฿13');
    });

    test('round-trips through toJson', () {
      final e = DriverEarnings.fromJson(
        DriverEarnings.fromJson(_earnings)!.toJson(),
      )!;
      expect(e.commissionLine, 'ค่าคอม 20% (฿13)');
    });
  });

  test('commissionPercent', () {
    expect(commissionPercent(0.2), '20%');
    expect(commissionPercent(0.125), '12.5%');
    expect(commissionPercent(0), '0%');
    expect(commissionPercent(null), isNull);
  });

  group('parcel payloads', () {
    test('the offer carries driver_earnings (WS / active-offer / offer)', () {
      final o = MessengerOffer.fromJson({
        'id': 'p1',
        'fare': 63,
        'driver_earnings': _earnings,
      });
      expect(o.driverEarnings?.driverNet, 50);
      expect(o.fare, 63);
    });

    test('an older offer has none', () {
      expect(MessengerOffer.fromJson({'id': 'p1', 'fare': 63}).driverEarnings,
          isNull);
    });

    test('the active / completed order carries it; the fee stays amount_due',
        () {
      final o = MessengerOrder.fromJson({
        'id': 'p1',
        'fare': 63,
        'amount_due': 63,
        'driver_earnings': _earnings,
      });
      expect(o.driverEarnings?.commissionLine, 'ค่าคอม 20% (฿13)');
      // What the customer is asked for is never reduced by the commission.
      expect(o.feeDue, 63);
    });

    test('an order built from the offer keeps its earnings', () {
      final o = MessengerOrder.fromOffer(MessengerOffer.fromJson({
        'id': 'p1',
        'fare': 63,
        'driver_earnings': _earnings,
      }));
      expect(o.driverEarnings?.driverNet, 50);
    });
  });

  test('the ride offer exposes its rate', () {
    final j = IncomingJobModel.fromJson({
      'id': 'r1',
      'pickup_address': 'a',
      'dropoff_address': 'b',
      'pickup_lat': 0,
      'pickup_lng': 0,
      'dropoff_lat': 0,
      'dropoff_lng': 0,
      'fare': 63,
      'payment_method': 'CASH',
      'driver_earnings': _earnings,
    });
    expect(j.earnings?.commissionLine, 'ค่าคอม 20% (฿13)');
  });

  group('ride trip history', () {
    final trips = {
      'data': [
        {'id': 'j1', 'driver_net': 50, 'commission': 13, 'commission_rate': 0.2},
        {'id': 'j2', 'driver_net': null, 'commission_rate': null},
      ],
    };

    test('the trip list carries commission_rate (null until settled)', () {
      final s = tripSummariesByJob(trips);
      expect(s['j1']?.commissionRate, 0.2);
      expect(s['j2']?.commissionRate, isNull);
    });

    test('the commission line shows the % beside it', () {
      expect(commissionLabel(0.2), 'หักค่าคอมมิชชัน 20%');
      expect(commissionLabel(null), 'หักค่าคอมมิชชัน');
    });

    test('the trip detail reads it', () {
      final d = historyDetailFromTrip(
        Map<String, dynamic>.from((trips['data'] as List).first as Map),
      );
      expect(d.commissionRate, 0.2);
    });
  });
}
