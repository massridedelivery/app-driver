import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/history_detail/presentation/controllers/history_detail_provider.dart';
import 'package:massdrive/features/history_detail/presentation/screens/widgets/payment_section.dart';
import 'package:massdrive/features/history_detail/presentation/screens/widgets/your_net_income_section.dart';

/// Flow 6 — trip detail (ประวัติ → รายละเอียดการให้บริการ).
Map<String, dynamic> _trip([Map<String, dynamic> extra = const {}]) => {
  'id': 'JOB-1',
  'created_at': '2026-09-19T03:19:00Z',
  'pickup_address': 'A',
  'dropoff_address': 'B',
  'distance_km': 0.39,
  'fare': 2,
  'payment_method': 'PROMPTPAY',
  'accepted_at': '2026-09-19T03:00:00Z',
  'completed_at': '2026-09-19T03:12:30Z',
  'updated_at': '2026-09-19T13:11:00Z',
  'gross_fare': 2,
  'commission': 0,
  'driver_net': 2,
  ...extra,
};

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  group('mapping a trip row', () {
    test('duration is accepted → completed, not → updated_at', () {
      final d = historyDetailFromTrip(_trip());
      expect(d.durationMinute, 12); // updated_at would give 611
    });

    test('no completion time → no duration (shown as "-")', () {
      final d = historyDetailFromTrip(_trip({'completed_at': null}));
      expect(d.durationMinute, isNull);
    });

    test('completed before accepted (bad data) → no duration', () {
      final d = historyDetailFromTrip(
        _trip({'completed_at': '2026-09-19T02:00:00Z'}),
      );
      expect(d.durationMinute, isNull);
    });

    test('earnings come from the backend whole-baht fields', () {
      final d = historyDetailFromTrip(
        _trip({
          'fare': 120,
          'gross_fare': 135,
          'commission': 27,
          'driver_net': 108,
        }),
      );
      expect(d.total, 120);
      expect(d.grossFare, 135);
      expect(d.commission, 27);
      expect(d.settledNet, 108);
      expect(d.grossFare! - d.commission!, d.settledNet);
    });

    test('an unsettled trip has no earnings yet', () {
      final d = historyDetailFromTrip(
        _trip({'gross_fare': null, 'commission': null, 'driver_net': null}),
      );
      expect(d.grossFare, isNull);
      expect(d.commission, isNull);
      expect(d.settledNet, isNull);
    });

    test('numbers as strings, payment label, distance', () {
      final d = historyDetailFromTrip(
        _trip({
          'fare': '82.5',
          'distance_km': '3.25',
          'payment_method': 'cash',
        }),
      );
      expect(d.total, 82.5);
      expect(d.distanceKm, 3.25);
      expect(d.paymentMethod, 'เงินสด');
      expect(historyDetailFromTrip(_trip()).paymentMethod, 'พร้อมเพย์ / QR');
    });
  });

  group('รายได้สุทธิของคุณ section', () {
    testWidgets('shows gross, commission and net from the backend', (t) async {
      final d = historyDetailFromTrip(
        _trip({
          'fare': 120,
          'gross_fare': 135,
          'commission': 27,
          'driver_net': 108,
        }),
      );
      await _pump(t, YourNetIncomeSection(data: d));
      expect(find.text('฿135'), findsOneWidget);
      expect(find.text('- ฿27'), findsOneWidget);
      expect(find.text('฿108'), findsOneWidget);
    });

    testWidgets('a ฿0 commission row is hidden', (t) async {
      await _pump(
        t,
        YourNetIncomeSection(data: historyDetailFromTrip(_trip())),
      );
      expect(find.text('หักค่าคอมมิชชัน'), findsNothing);
      expect(find.text('฿2'), findsNWidgets(2)); // fare + net
    });

    testWidgets('an unsettled trip says รอสรุปยอด instead of a guess', (
      t,
    ) async {
      final d = historyDetailFromTrip(
        _trip({'gross_fare': null, 'commission': null, 'driver_net': null}),
      );
      await _pump(t, YourNetIncomeSection(data: d));
      expect(find.text('รอสรุปยอด'), findsOneWidget);
      expect(find.text('฿2'), findsOneWidget); // fare falls back to `fare`
    });
  });

  group('รายละเอียดการชำระเงิน section', () {
    testWidgets('method, distance, duration and total', (t) async {
      final d = historyDetailFromTrip(_trip({'fare': 82.5}));
      await _pump(t, PaymentSection(data: d));
      expect(find.text('พร้อมเพย์ / QR'), findsOneWidget);
      expect(find.text('0.39 km'), findsOneWidget);
      expect(find.text('12 นาที'), findsOneWidget);
      expect(find.text('฿82.50'), findsOneWidget);
    });

    testWidgets('missing completion time shows "-"', (t) async {
      final d = historyDetailFromTrip(_trip({'completed_at': null}));
      await _pump(t, PaymentSection(data: d));
      expect(find.text('-'), findsOneWidget);
      expect(find.textContaining('นาที'), findsNothing);
    });
  });
}
