import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/features/history/data/models/history_item_api_model.dart';
import 'package:massdrive/features/history/domain/models/service_icon.dart';
import 'package:massdrive/features/history/domain/models/trip_history_rows.dart';

/// Flow 9 — ประวัติการให้บริการ list.
HistoryListResponseModel _page(List<Map<String, dynamic>> txns) =>
    HistoryListResponseModel.fromJson({'transactions': txns});

final _txns = [
  {
    'id': 't1',
    'job_id': '03d8f581-ff91-4362-a94c-c88100d69d18',
    'type': 'COMMISSION_DEDUCTION',
    'amount': -0.4,
    'status': 'COMPLETED',
    'description': 'Commission for #JOB-03d8f581-ff91-4362-a94c-c88100d69d18',
    'created_at': '2026-09-19T03:19:34Z',
  },
  {
    'id': 't2',
    'job_id': '03d8f581-ff91-4362-a94c-c88100d69d18',
    'type': 'FARE_PAYMENT',
    'amount': 2,
    'status': 'COMPLETED',
    'description': 'Trip #JOB-03d8f581-ff91-4362-a94c-c88100d69d18',
    'created_at': '2026-09-19T03:19:33Z',
  },
  {
    'id': 't3',
    'type': 'TOPUP',
    'amount': 100,
    'status': 'COMPLETED',
    'description': 'topup',
    'created_at': '2026-08-11T18:35:00Z',
  },
  {
    'id': 't4',
    'type': 'ADJUSTMENT',
    'amount': 100,
    'status': 'COMPLETED',
    'description': 'adjustment',
    'created_at': '2026-08-11T18:35:00Z',
  },
  {
    'id': 't5',
    'job_id': 'f00d0000-0000-0000-0000-000000000000',
    'type': 'FARE_PAYMENT',
    'service': 'food',
    'amount': 45,
    'status': 'COMPLETED',
    'created_at': '2026-09-20T05:00:00Z',
  },
];

void main() {
  final items = _page(_txns).data.map((m) => m.toEntity()).toList();
  final response = {
    'data': [
      {
        'id': '03d8f581-ff91-4362-a94c-c88100d69d18',
        'driver_info': {'vehicle_type_name': 'motorcycle'},
      },
      {'id': 'other', 'vehicle_type_name': 'premium'},
      {'id': 'no-type'},
    ],
  };
  final vehicles = vehicleTypesByJob(response);
  final trips = tripSummariesByJob(response);

  group('rows', () {
    test('only trip entries stay — top-up and adjustment are left out', () {
      final rows = tripRows(items, trips);
      expect(rows.map((r) => r.id), ['t1', 't2', 't5']);
      expect(rows.map((r) => r.title), isNot(contains('adjustment')));
      expect(rows.map((r) => r.title), isNot(contains('เติมเงินเครดิต')));
    });

    test('titles are Thai with the short job id', () {
      final rows = tripRows(items, trips);
      expect(rows[0].title, 'ค่าคอมมิชชัน (งาน #03d8f5)');
      expect(rows[1].title, 'รายได้จากงาน #03d8f5');
    });

    test('amounts keep their sign and satang', () {
      final rows = tripRows(items, trips);
      expect(formatSignedBaht(rows[0].amount!), '-฿0.40');
      expect(formatSignedBaht(rows[1].amount!), '฿2');
    });

    test('time is the local time, not UTC', () {
      final row = tripRows(items, trips)[1];
      expect(row.dateTime.isUtc, isFalse);
      expect(row.dateTime, DateTime.utc(2026, 9, 19, 3, 19, 33).toLocal());
    });

    test('each row carries its job vehicle type', () {
      final rows = tripRows(items, trips);
      expect(rows[0].vehicleTypeName, 'motorcycle');
      expect(rows[2].vehicleTypeName, isNull);
      expect(rows[2].service, 'food');
    });
  });

  group('vehicle types from the trip list', () {
    test('reads driver_info.vehicle_type_name, then a top-level one', () {
      expect(vehicles, {
        '03d8f581-ff91-4362-a94c-c88100d69d18': 'motorcycle',
        'other': 'premium',
      });
    });

    test('a bad or empty response is no vehicles, not a crash', () {
      expect(vehicleTypesByJob(null), isEmpty);
      expect(vehicleTypesByJob({'data': 'x'}), isEmpty);
      expect(vehicleTypesByJob([]), isEmpty);
    });
  });

  group('icon', () {
    const dir = 'assets/images/icons/vehicles';

    test('same mapping as the customer app', () {
      expect(
        serviceIconAsset(vehicleTypeName: 'motorcycle'),
        '$dir/ic_car_scooter.png',
      );
      expect(
        serviceIconAsset(vehicleTypeName: 'Standard Bike'),
        '$dir/ic_car_scooter.png',
      );
      expect(
        serviceIconAsset(vehicleTypeName: 'premium'),
        '$dir/ic_car_premium.png',
      );
      expect(
        serviceIconAsset(vehicleTypeName: 'luxury'),
        '$dir/ic_car_luxury.png',
      );
      expect(serviceIconAsset(vehicleTypeName: 'suv_6'), '$dir/ic_car_xl.png');
      expect(
        serviceIconAsset(vehicleTypeName: 'comfort'),
        '$dir/ic_car_comfort.png',
      );
      expect(
        serviceIconAsset(vehicleTypeName: 'tuktuk'),
        '$dir/ic_car_tuktuk.png',
      );
      expect(
        serviceIconAsset(vehicleTypeName: 'economy'),
        '$dir/ic_car_economy.png',
      );
      expect(
        serviceIconAsset(vehicleTypeName: 'taxi'),
        '$dir/ic_car_economy.png',
      );
    });

    test('food / messenger by service; unknown ride → generic ride', () {
      expect(serviceIconAsset(service: 'food'), '$dir/ic3d_food.png');
      expect(serviceIconAsset(service: 'messenger'), '$dir/ic3d_messenger.png');
      expect(serviceIconAsset(), '$dir/ic3d_ride.png');
    });

    test('every icon the mapping can return exists in assets', () {
      final names = [
        'motorcycle',
        'premium',
        'luxury',
        'xl',
        'comfort',
        'tuk',
        'economy',
      ];
      final paths = {
        for (final n in names) serviceIconAsset(vehicleTypeName: n),
        serviceIconAsset(service: 'food'),
        serviceIconAsset(service: 'messenger'),
        serviceIconAsset(),
      };
      for (final p in paths) {
        expect(File(p).existsSync(), isTrue, reason: p);
      }
    });
  });
}
