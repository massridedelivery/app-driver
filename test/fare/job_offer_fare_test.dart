import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/features/incoming_job/domain/models/food_order_lines.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';

/// Flow 1 — the job offer card (ride + food): the fare the driver decides on.
Map<String, dynamic> _offer([Map<String, dynamic> extra = const {}]) => {
  'id': 'JOB-1',
  'pickup_address': 'A',
  'dropoff_address': 'B',
  'pickup_lat': 13.7,
  'pickup_lng': 100.5,
  'dropoff_lat': 13.8,
  'dropoff_lng': 100.6,
  'payment_method': 'CASH',
  'fare': 82.83,
  ...extra,
};

void main() {
  group('ride offer', () {
    test('fare is read from `fare` and shown with satang, not truncated', () {
      final job = IncomingJobModel.fromJson(_offer());
      expect(job.netIncome, 82.83);
      // The offer card used to show `.toInt()` → "82".
      expect(formatBahtNumber(job.netIncome), '82.83');
    });

    test('a whole fare shows as a whole number', () {
      final job = IncomingJobModel.fromJson(_offer({'fare': 45}));
      expect(formatBahtNumber(job.netIncome), '45');
    });

    test('amount_due is optional and separate from the display fare', () {
      expect(IncomingJobModel.fromJson(_offer()).amountDue, isNull);
      final job = IncomingJobModel.fromJson(_offer({'amount_due': 95}));
      expect(job.amountDue, 95);
      expect(job.netIncome, 82.83);
    });
  });

  group('food offer lines', () {
    test(
      'reads the backend order item shape (quantity / unit_price / subtotal)',
      () {
        final line = FoodOrderLine.fromMap({
          'name': 'ข้าวมันไก่',
          'quantity': 2,
          'unit_price': 50,
          'subtotal': 110, // includes a ฿10 modifier
          'notes': 'ไม่เอาหนัง',
        });
        expect(line.name, 'ข้าวมันไก่');
        expect(line.qty, 2);
        expect(line.unitPrice, 50);
        expect(line.lineTotal, 110);
        expect(line.note, 'ไม่เอาหนัง');
      },
    );

    test(
      'reads the legacy shape (qty / price) and multiplies for the line',
      () {
        final line = FoodOrderLine.fromMap({
          'name': 'ชาเย็น',
          'qty': 3,
          'price': 25,
        });
        expect(line.qty, 3);
        expect(line.lineTotal, 75);
        expect(line.note, isNull);
      },
    );

    test('tolerates numbers as double or string, and a missing/zero qty', () {
      expect(
        FoodOrderLine.fromMap({'qty': 2.0, 'price': '12.5'}).lineTotal,
        25,
      );
      expect(FoodOrderLine.fromMap({'price': 30}).qty, 1);
      expect(FoodOrderLine.fromMap({'qty': 0, 'price': 30}).lineTotal, 30);
      expect(FoodOrderLine.fromMap({}).lineTotal, 0);
    });
  });

  group('food offer totals', () {
    final lines = FoodOrderLine.listFrom([
      {'name': 'A', 'quantity': 2, 'unit_price': 50},
      {'name': 'B', 'quantity': 1, 'unit_price': 35.5},
    ]);

    test('sums the lines when the backend sends no subtotal', () {
      final t = FoodOrderTotals.from(lines: lines, deliveryFee: 20);
      expect(t.itemsSubtotal, 135.5);
      expect(t.deliveryFee, 20);
      expect(t.total, 155.5);
      expect(formatBaht(t.total), '฿155.50');
    });

    test("the backend's subtotal wins over the summed lines", () {
      final t = FoodOrderTotals.from(
        lines: lines,
        subtotal: 120,
        deliveryFee: 20,
      );
      expect(t.itemsSubtotal, 120);
      expect(t.total, 140);
    });

    test('no items and no fees is ฿0, not an error', () {
      final t = FoodOrderTotals.from(lines: FoodOrderLine.listFrom(null));
      expect(t.total, 0);
    });

    test('order_items on the offer feed the same lines', () {
      final job = IncomingJobModel.fromJson(
        _offer({
          'service_type': 'food',
          'delivery_fee': 15,
          'order_items': [
            {'name': 'A', 'quantity': 2, 'unit_price': 40},
          ],
        }),
      );
      final t = FoodOrderTotals.from(
        lines: FoodOrderLine.listFrom(job.orderItems),
        subtotal: job.subtotal,
        deliveryFee: job.deliveryFee,
      );
      expect(job.isFood, isTrue);
      expect(t.itemsSubtotal, 80);
      expect(t.total, 95);
    });
  });
}
