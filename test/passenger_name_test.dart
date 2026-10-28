import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';

Map<String, dynamic> _job(Map<String, dynamic> extra) => {
  'id': 'J',
  'pickup_address': 'A',
  'dropoff_address': 'B',
  'pickup_lat': 13.0,
  'pickup_lng': 100.0,
  'dropoff_lat': 13.1,
  'dropoff_lng': 100.1,
  'fare': 74,
  'payment_method': 'CASH',
  ...extra,
};

void main() {
  test('name from customer_info (what the active job sends)', () {
    final j = IncomingJobModel.fromJson(
      _job({
        'customer_info': {'full_name': 'สมชาย ใจดี', 'phone': ''},
      }),
    );
    expect(j.passengerName, 'สมชาย ใจดี');
  });

  test('older shapes still work: flat passenger_name, nested customer', () {
    expect(
      IncomingJobModel.fromJson(_job({'passenger_name': 'ก'})).passengerName,
      'ก',
    );
    expect(
      IncomingJobModel.fromJson(
        _job({
          'customer': {'full_name': 'ข'},
        }),
      ).passengerName,
      'ข',
    );
  });

  test('no name anywhere → the default', () {
    expect(IncomingJobModel.fromJson(_job({})).passengerName, 'ผู้โดยสาร');
  });
}
