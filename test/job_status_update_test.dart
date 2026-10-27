import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/managers/api/api_exception.dart';
import 'package:massdrive/features/job_live/domain/job_status_update.dart';
import 'package:massdrive/features/job_live/domain/models/active_item.dart';
import 'package:massdrive/features/job_live/domain/repositories/job_live_repository.dart';

class _FakeRepo implements JobLiveRepository {
  _FakeRepo([this.error]);

  final Object? error;
  final sent = <Map<String, dynamic>>[];

  @override
  Future<void> updateJobStatus(String jobId, Map<String, dynamic> data) async {
    sent.add(data);
    if (error != null) throw error!;
  }

  @override
  Future<void> cancelJob(String jobId, Map<String, dynamic> data) async {}
  @override
  Future<void> arriveAtStop(String jobId, String stopId) async {}
  @override
  Future<void> departFromStop(String jobId, String stopId) async {}
  @override
  Future<void> acceptJob(String jobId) async {}
  @override
  Future<List<ActiveItem>> getActiveSummary() async => [];
  @override
  Future<dynamic> getActiveJob({double? lat, double? lng}) async => null;
  @override
  Future<dynamic> getActiveOffer({double? lat, double? lng}) async => null;
  @override
  Future<dynamic> getActiveFoodOrder({double? lat, double? lng}) async => null;
}

Future<({double lat, double lng})?> _here() async => (lat: 13.7, lng: 100.5);
Future<({double lat, double lng})?> _nowhere() async => null;

void main() {
  test('arrival sends status + position and succeeds on 2xx', () async {
    final repo = _FakeRepo();
    final r = await sendJobStatus(
      repo: repo,
      jobId: 'j1',
      status: 'ARRIVED_AT_PICK_UP',
      locate: _here,
    );
    expect(r.ok, isTrue);
    expect(repo.sent.single, {
      'status': 'ARRIVED_AT_PICK_UP',
      'lat': 13.7,
      'lng': 100.5,
    });
  });

  test('too far: refused with the distances in Thai', () async {
    final repo = _FakeRepo(
      const ApiException(
        400,
        message:
            'too far from pickup point to mark as arrived (350m away, limit 200m)',
      ),
    );
    final r = await sendJobStatus(
      repo: repo,
      jobId: 'j1',
      status: 'ARRIVED_AT_PICK_UP',
      locate: _here,
    );
    expect(r.outcome, JobStatusOutcome.refused);
    expect(
      r.message,
      'ยังอยู่ห่างจุดรับเกิน 200 เมตร (ห่าง 350 เมตร) กรุณาเข้าใกล้จุดรับก่อน',
    );
  });

  test('too far without numbers falls back to generic copy', () {
    expect(
      statusErrorMessage('too far from pickup point'),
      'ยังอยู่ห่างจุดรับเกินระยะที่กำหนด กรุณาเข้าใกล้จุดรับก่อน',
    );
  });

  test('no GPS fix: arrival is not sent', () async {
    final repo = _FakeRepo();
    final r = await sendJobStatus(
      repo: repo,
      jobId: 'j1',
      status: 'ARRIVED_AT_PICK_UP',
      locate: _nowhere,
    );
    expect(r.outcome, JobStatusOutcome.noLocation);
    expect(r.message, noLocationMessage);
    expect(repo.sent, isEmpty);
  });

  test('backend asking for coordinates maps to no-location', () async {
    final r = await sendJobStatus(
      repo: _FakeRepo(
        const ApiException(
          400,
          message: 'location coordinates are required to mark arrival',
        ),
      ),
      jobId: 'j1',
      status: 'ARRIVED_AT_PICK_UP',
      locate: _here,
    );
    expect(r.outcome, JobStatusOutcome.noLocation);
  });

  test('409 means the job was cancelled', () async {
    final r = await sendJobStatus(
      repo: _FakeRepo(const ApiException(409, message: 'job cancelled')),
      jobId: 'j1',
      status: 'PICKED_UP',
      locate: _here,
    );
    expect(r.outcome, JobStatusOutcome.cancelled);
  });

  test('pickup without a fix is still sent, minus the position', () async {
    final repo = _FakeRepo();
    final r = await sendJobStatus(
      repo: repo,
      jobId: 'j1',
      status: 'PICKED_UP',
      locate: _nowhere,
    );
    expect(r.ok, isTrue);
    expect(repo.sent.single, {'status': 'PICKED_UP'});
  });

  test('other errors pass the backend message through', () async {
    final r = await sendJobStatus(
      repo: _FakeRepo(const ApiException(400, message: 'invalid transition')),
      jobId: 'j1',
      status: 'PICKED_UP',
      locate: _here,
    );
    expect(r.outcome, JobStatusOutcome.refused);
    expect(r.message, 'invalid transition');
  });
}
