import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/common/widgets/earnings/day_job_groups.dart';
import 'package:massdrive/common/widgets/earnings/job_earnings_card.dart';
import 'package:massdrive/features/history/data/models/history_item_api_model.dart';
import 'package:massdrive/features/history/domain/models/trip_history_rows.dart';

/// Flow 11 — the shared job card (design E) on รายการทั้งหมด and
/// ประวัติการให้บริการ.
Future<void> _pump(WidgetTester t, Widget w) =>
    t.pumpWidget(MaterialApp(home: Scaffold(body: w)));

void main() {
  group('JobEarningsCard', () {
    testWidgets('vehicle, job id, lines and the backend net', (t) async {
      await _pump(
        t,
        JobEarningsCard(
          jobId: '03d8f581-ff91',
          time: DateTime(2026, 9, 19, 10, 19),
          vehicleTypeName: 'motorcycle',
          pickupAddress: 'ซอยหมู่บ้านท่าน้ำนนท์วิลเลจ',
          driverNet: 2,
          lines: const [
            JobCardLine(label: 'ค่าโดยสาร', amount: 2),
            JobCardLine(label: 'หักค่าคอมมิชชัน', amount: -0.4),
          ],
        ),
      );
      expect(find.text('มอเตอร์ไซค์ · งาน #03d8f5'), findsOneWidget);
      expect(find.text('10:19 · ซอยหมู่บ้านท่าน้ำนนท์วิลเลจ'), findsOneWidget);
      expect(find.text('+฿2'), findsOneWidget);
      expect(find.text('-฿0.40'), findsOneWidget);
      expect(find.text('฿2'), findsOneWidget); // รายได้สุทธิ = driver_net
      final img = t.widget<Image>(find.byType(Image));
      expect(
        (img.image as AssetImage).assetName,
        'assets/images/icons/vehicles/ic_car_scooter.png',
      );
    });

    testWidgets('no backend net yet → รอสรุปยอด, never a sum', (t) async {
      await _pump(
        t,
        JobEarningsCard(
          jobId: 'JOB-B',
          time: DateTime(2026, 9, 19, 0, 7),
          lines: const [JobCardLine(label: 'ค่าโดยสาร', amount: 85)],
        ),
      );
      expect(find.text('รอสรุปยอด'), findsOneWidget);
      expect(find.text('เรียกรถ · งาน #JOB-B'), findsOneWidget);
      expect(find.text('00:07'), findsOneWidget);
    });

    testWidgets('design 5: net in green, debit in red (dark + light)', (
      t,
    ) async {
      Future<void> pumpIn(Brightness b) => t.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: b),
          home: Scaffold(
            body: JobEarningsCard(
              jobId: 'J',
              time: DateTime(2026),
              driverNet: 2,
              lines: const [
                JobCardLine(label: 'หักค่าคอมมิชชัน', amount: -0.4),
              ],
            ),
          ),
        ),
      );
      Color colorOf(String text) =>
          t.widget<Text>(find.text(text)).style!.color!;

      await pumpIn(Brightness.dark);
      expect(colorOf('฿2'), const Color(0xFF4ADE80));
      expect(colorOf('-฿0.40'), const Color(0xFFFCA5A5));

      await pumpIn(Brightness.light);
      await t.pumpAndSettle(); // the theme change animates
      expect(colorOf('฿2'), const Color(0xFF15803D));
      expect(colorOf('-฿0.40'), const Color(0xFFB91C1C));
    });

    testWidgets('tapping opens the detail', (t) async {
      var tapped = false;
      await _pump(
        t,
        JobEarningsCard(
          jobId: 'J',
          time: DateTime(2026),
          lines: const [],
          onTap: () => tapped = true,
        ),
      );
      await t.tap(find.byType(JobEarningsCard));
      expect(tapped, isTrue);
    });
  });

  group('history rows as cards', () {
    final rows = HistoryListResponseModel.fromJson({
      'transactions': [
        {
          'id': 'c',
          'job_id': 'JOB-A',
          'type': 'COMMISSION_DEDUCTION',
          'amount': -0.4,
          'created_at': '2026-09-19T03:19:34Z',
          'description': 'Commission for #JOB-JOB-A',
        },
        {
          'id': 'f',
          'job_id': 'JOB-A',
          'type': 'FARE_PAYMENT',
          'amount': 2,
          'created_at': '2026-09-19T03:19:33Z',
          'pickup_address': 'ซอย A',
        },
      ],
    }).data.map((m) => m.toEntity()).toList();
    final trips = tripSummariesByJob({
      'data': [
        {
          'id': 'JOB-A',
          'driver_info': {'vehicle_type_name': 'motorcycle'},
          'driver_net': 2,
        },
      ],
    });

    test('one job → one group, fare first, with the trip net + pickup', () {
      final entries = groupByDayAndJob(
        tripRows(rows, trips),
        time: (i) => i.dateTime,
        jobId: (i) => i.jobId,
      );
      final group = entries.whereType<JobGroup>().single;
      final ordered = jobCardOrder(group.items.cast());
      expect(ordered.map(historyLineLabel), ['ค่าโดยสาร', 'หักค่าคอมมิชชัน']);
      expect(ordered.first.tripNet, 2);
      expect(ordered.first.vehicleTypeName, 'motorcycle');
      expect(ordered.first.pickupAddress, 'ซอย A');
    });

    test('other row types keep their own title', () {
      final bonus = HistoryListResponseModel.fromJson({
        'transactions': [
          {
            'id': 'b',
            'job_id': 'J',
            'type': 'BONUS',
            'description': 'โบนัสภารกิจ',
          },
        ],
      }).data.single.toEntity();
      expect(historyLineLabel(bonus), 'โบนัสภารกิจ');
    });
  });

  test('generic grouping: day headers, singles and job groups', () {
    final items = [
      (at: DateTime.utc(2026, 9, 19, 5), job: 'A'),
      (at: DateTime.utc(2026, 9, 19, 4), job: null),
      (at: DateTime.utc(2026, 9, 19, 3), job: 'A'),
      (at: DateTime.utc(2026, 9, 10, 5), job: 'A'),
    ];
    final out = groupByDayAndJob(items, time: (i) => i.at, jobId: (i) => i.job);
    expect(out.whereType<DayHeader>().length, 2);
    expect(out.whereType<SingleRow>().length, 1);
    final groups = out.whereType<JobGroup>().toList();
    expect(groups.length, 2); // same job, two days → two cards
    expect(groups.first.items.length, 2);
  });
}
