import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/history/domain/models/trip_summary.dart';
import 'package:massdrive/features/profile/domain/trip_calendar_entries.dart';
import 'package:massdrive/features/wallet/data/models/transaction_model.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction.dart';

/// ตารางรายได้: the headline is the jobs' net earnings, not their fares.
Transaction _tx(Map<String, dynamic> j) => TransactionModel.fromJson({
  'id': 't',
  'type': 'FARE_PAYMENT',
  'status': 'COMPLETED',
  'created_at': '2026-10-17T08:08:00Z',
  ...j,
}).toEntity();

void main() {
  // 17 Oct on A07: fares 63 / 63 / 43 read "รายได้สุทธิ ฿169"; nets 54/54/37.
  final rows = [
    _tx({'job_id': 'A', 'amount': 63, 'created_at': '2026-10-17T08:08:00Z'}),
    _tx({'job_id': 'A', 'type': 'COMMISSION_DEDUCTION', 'amount': -9}),
    _tx({'job_id': 'A', 'type': 'marketing_expense', 'amount': 50}),
    _tx({'job_id': 'B', 'amount': 63, 'created_at': '2026-10-17T06:48:00Z'}),
    _tx({'job_id': 'B', 'type': 'COMMISSION_DEDUCTION', 'amount': -9}),
    _tx({'job_id': 'C', 'amount': 43, 'created_at': '2026-10-17T06:46:00Z'}),
    _tx({'job_id': 'C', 'type': 'COMMISSION_DEDUCTION', 'amount': -6}),
  ];

  test('net per job from driver_net; the total is ฿145, not ฿169', () {
    final summaries = tripSummariesByJob({
      'data': [
        {
          'id': 'A',
          'driver_net': 54,
          'driver_info': {'vehicle_type_name': 'motorcycle'},
        },
        {'id': 'B', 'driver_net': 54},
        {'id': 'C', 'driver_net': 37},
      ],
    });
    final trips = calendarTrips(rows, summaries);
    expect(trips.map((t) => t.jobId), ['A', 'B', 'C']); // newest first
    expect(trips.map((t) => t.net), [54, 54, 37]);
    expect(trips.first.vehicleTypeName, 'motorcycle');
    expect(calendarNet(trips), 145);
  });

  test('without driver_net: fare + commission rows; promo never adds', () {
    final trips = calendarTrips(rows, const {});
    expect(trips.map((t) => t.net), [54, 54, 37]);
    expect(calendarNet(trips), 145);
  });

  test('failed rows, rows without a job, and jobs without a fare are out', () {
    final trips = calendarTrips([
      _tx({'job_id': 'X', 'amount': 80, 'status': 'FAILED'}),
      _tx({'amount': 100, 'type': 'TOPUP'}),
      _tx({'job_id': 'Y', 'type': 'COMMISSION_DEDUCTION', 'amount': -5}),
      _tx({'job_id': 'Z', 'amount': 40}),
    ], const {});
    expect(trips.map((t) => t.jobId), ['Z']);
    expect(calendarNet(trips), 40);
    expect(calendarNet(const []), 0);
  });
}
