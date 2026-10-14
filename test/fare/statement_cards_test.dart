import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/history/domain/models/service_icon.dart';
import 'package:massdrive/features/history/domain/models/trip_history_rows.dart';
import 'package:massdrive/features/income/presentation/money_text.dart';
import 'package:massdrive/features/income/presentation/statement_entries.dart';
import 'package:massdrive/features/wallet/data/models/transaction_model.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction.dart';
import 'package:massdrive/features/wallet/domain/enums/transaction_type.dart';

/// Flow 10 — รายการทั้งหมด as job cards (design E).
Transaction _tx(String id, String type, num amount, String at, {String? job}) =>
    TransactionModel.fromJson({
      'id': id,
      'type': type,
      'amount': amount,
      'status': 'COMPLETED',
      'created_at': at,
      if (job != null) 'job_id': job,
      if (job != null) 'pickup_address': 'ซอยหมู่บ้านท่าน้ำนนท์วิลเลจ',
    }).toEntity();

void main() {
  // Newest first, as the API sends them.
  final txns = [
    _tx(
      'c1',
      'COMMISSION_DEDUCTION',
      -0.4,
      '2026-09-19T03:19:34Z',
      job: 'JOB-A',
    ),
    _tx('f1', 'FARE_PAYMENT', 2, '2026-09-19T03:19:33Z', job: 'JOB-A'),
    _tx(
      'c2',
      'COMMISSION_DEDUCTION',
      -0.4,
      '2026-09-18T17:07:47Z',
      job: 'JOB-B',
    ),
    _tx('f2', 'FARE_PAYMENT', 2, '2026-09-18T17:07:46Z', job: 'JOB-B'),
    _tx('t1', 'TOPUP', 100, '2026-08-11T18:35:00Z'),
    _tx('a1', 'ADJUSTMENT', 100, '2026-08-11T18:35:00Z'),
  ];

  group('building the statement', () {
    final entries = buildStatement(txns);

    test('one card per job, plain rows for top-up / adjustment', () {
      final jobs = entries.whereType<StatementJob>().toList();
      expect(jobs.map((j) => j.jobId), ['JOB-A', 'JOB-B']);
      expect(entries.whereType<StatementTxn>().map((t) => t.transaction.id), [
        't1',
        'a1',
      ]);
    });

    test('the card lists the fare first, then the commission', () {
      final a = entries.whereType<StatementJob>().first;
      expect(a.transactions.map((t) => t.type), [
        TransactionType.farePayment,
        TransactionType.commissionDeduction,
      ]);
      expect(a.transactions.map(transactionAmountText), ['+฿2', '-฿0.40']);
    });

    test('a day header before each local day', () {
      final days = entries.whereType<StatementDay>().map((d) => d.date.day);
      // 2026-09-18T17:07Z is already the 19th in Thailand (UTC+7) — the
      // header follows the local day, whatever the test machine's zone.
      final local = txns.map((t) => t.createdAt.toLocal().day).toSet();
      expect(days.toSet(), local);
      expect(entries.first, isA<StatementDay>());
    });

    test('card time is its newest row and pickup comes from any row', () {
      final a = entries.whereType<StatementJob>().first;
      expect(a.time, DateTime.parse('2026-09-19T03:19:34Z'));
      expect(a.pickupAddress, 'ซอยหมู่บ้านท่าน้ำนนท์วิลเลจ');
    });

    test('the same job on two different days makes two cards', () {
      final split = buildStatement([
        _tx('c', 'COMMISSION_DEDUCTION', -1, '2026-09-20T05:00:00Z', job: 'J'),
        _tx('f', 'FARE_PAYMENT', 5, '2026-09-10T05:00:00Z', job: 'J'),
      ]);
      expect(split.whereType<StatementJob>().length, 2);
    });

    test('nothing in → nothing out', () {
      expect(buildStatement(const []), isEmpty);
    });
  });

  group('trip summaries (vehicle + backend net)', () {
    final trips = tripSummariesByJob({
      'data': [
        {
          'id': 'JOB-A',
          'driver_info': {'vehicle_type_name': 'motorcycle'},
          'driver_net': 2,
        },
        {'id': 'JOB-B', 'vehicle_type_name': 'economy', 'driver_net': null},
      ],
    });

    test('net is the backend driver_net, null until settled', () {
      expect(trips['JOB-A']!.driverNet, 2);
      expect(trips['JOB-B']!.driverNet, isNull);
      expect(trips['JOB-X'], isNull);
    });

    test('vehicle type from driver_info or top level', () {
      expect(trips['JOB-A']!.vehicleTypeName, 'motorcycle');
      expect(trips['JOB-B']!.vehicleTypeName, 'economy');
    });

    test('bad responses are empty', () {
      expect(tripSummariesByJob(null), isEmpty);
      expect(tripSummariesByJob({'data': 1}), isEmpty);
    });
  });

  test('card title names the service / vehicle in Thai', () {
    expect(serviceLabel(vehicleTypeName: 'motorcycle'), 'มอเตอร์ไซค์');
    expect(serviceLabel(vehicleTypeName: 'Standard Bike'), 'มอเตอร์ไซค์');
    expect(serviceLabel(vehicleTypeName: 'economy'), 'รถยนต์');
    expect(serviceLabel(vehicleTypeName: 'taxi'), 'แท็กซี่');
    expect(serviceLabel(vehicleTypeName: 'premium'), 'รถพรีเมียม');
    expect(serviceLabel(vehicleTypeName: 'luxury'), 'รถหรู');
    expect(serviceLabel(vehicleTypeName: 'suv_6'), 'รถ 6 ที่นั่ง');
    expect(serviceLabel(vehicleTypeName: 'tuktuk'), 'ตุ๊กตุ๊ก');
    expect(serviceLabel(service: 'food'), 'ส่งอาหาร');
    expect(serviceLabel(service: 'messenger'), 'ส่งพัสดุ');
    expect(serviceLabel(), 'เรียกรถ');
  });
}
