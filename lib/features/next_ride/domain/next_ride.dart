import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';

/// Back-to-back rides (งานต่อเนื่อง, BE `b2b_dispatch_enabled`). A driver with
/// a passenger on board, close to the drop-off, can be offered a ride waiting
/// near it as their next one (WS `job_offer_next`). Accepting queues it: it
/// starts by itself the moment they complete the trip they are on (the
/// backend sends its `job_accepted` straight away).

/// WS frame of a back-to-back offer. After a reconnect the same offer is
/// re-sent as a plain `job_offer`, still carrying `job.next_offer`.
const nextOfferFrameType = 'job_offer_next';

/// WS frame: the accepted next ride is queued {job_id, job, arrive_by}.
const jobQueuedFrameType = 'job_queued';

/// WS frame: the queued ride stopped waiting {job_id, reason}.
const jobUnqueuedFrameType = 'job_unqueued';

/// `job.next_offer` on a back-to-back offer (BE job.NextOffer).
class NextOfferInfo {
  const NextOfferInfo({
    required this.afterJobId,
    required this.etaToDropoffMin,
    required this.etaToPickupMin,
  });

  /// The trip the driver is on now.
  final String afterJobId;

  /// Minutes until the current passenger is dropped off.
  final int etaToDropoffMin;

  /// Minutes from now to this ride's pickup, the current trip included
  /// (BE internal/dispatch/nextup.go: drop-off ETA + the drive from there).
  final int etaToPickupMin;

  static NextOfferInfo? fromJson(Object? raw) {
    if (raw is! Map) return null;
    return NextOfferInfo(
      afterJobId: raw['after_job_id']?.toString() ?? '',
      etaToDropoffMin: _int(raw['eta_to_dropoff_min']) ?? 0,
      etaToPickupMin: _int(raw['eta_to_pickup_min']) ?? 0,
    );
  }
}

/// A next-ride offer on screen: the ride, its `next_offer`, and when the
/// accept window closes (the backend sends no expiry; the app's usual 16 s).
class NextRideOffer {
  const NextRideOffer({
    required this.job,
    required this.info,
    required this.expiresAt,
    required this.totalSeconds,
  });

  final IncomingJobModel job;
  final NextOfferInfo info;
  final DateTime expiresAt;
  final int totalSeconds;

  String get jobId => job.jobId;

  /// Whole seconds left at [now], never below 0.
  int remainingAt(DateTime now) {
    final ms = expiresAt.difference(now).inMilliseconds;
    if (ms <= 0) return 0;
    return (ms / 1000).ceil();
  }

  /// "ส่งผู้โดยสารเสร็จใน ~4 นาที · ถึงจุดรับใน ~7 นาที" — the two backend
  /// ETAs as sent; a zero (unknown) one is left out.
  String get etaLine => nextRideEtaLine(info);
}

/// [NextOfferInfo]'s ETAs for the card. `eta_to_pickup_min` already counts
/// the current trip, so it is shown as is, never added to the drop-off one.
String nextRideEtaLine(NextOfferInfo info) => [
  if (info.etaToDropoffMin > 0)
    'ส่งผู้โดยสารเสร็จใน ~${info.etaToDropoffMin} นาที',
  if (info.etaToPickupMin > 0) 'ถึงจุดรับใน ~${info.etaToPickupMin} นาที',
].join(' · ');

/// A ride queued as the driver's next one (the banner).
class QueuedNextRide {
  const QueuedNextRide({
    required this.jobId,
    required this.pickupAddress,
    this.job,
    this.arriveBy,
    this.etaMin,
  });

  final String jobId;
  final String pickupAddress;

  /// The ride as the backend sent it, when it parsed (no customer_info until
  /// it starts).
  final IncomingJobModel? job;

  /// The deadline (not an ETA): not at the pickup by then, the ride goes
  /// back to dispatch. Accept time + the offered eta_to_pickup_min + the
  /// admin's b2b_queue_grace_min. From `job_queued.arrive_by` or
  /// `queued_next.arrive_by` (RFC 3339 with offset, maybe fractional seconds).
  final DateTime? arriveBy;

  /// `queued_next.eta_min`: minutes to the pickup, the current trip included
  /// (GET /jobs/next only; job_queued carries none).
  final int? etaMin;

  QueuedNextRide merge(QueuedNextRide other) => QueuedNextRide(
    jobId: jobId,
    pickupAddress: other.pickupAddress.isNotEmpty
        ? other.pickupAddress
        : pickupAddress,
    job: other.job ?? job,
    arriveBy: other.arriveBy ?? arriveBy,
    etaMin: other.etaMin ?? etaMin,
  );

  /// "งานถัดไป: รับที่ …".
  String get bannerTitle => 'งานถัดไป: รับที่ $pickupAddress';

  /// "ไปให้ถึงจุดรับก่อน 14:32" in Bangkok time, whatever the phone's zone;
  /// null without a deadline.
  String? get arriveByLine {
    final at = arriveBy?.toUtc().add(const Duration(hours: 7));
    if (at == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    return 'ไปให้ถึงจุดรับก่อน ${two(at.hour)}:${two(at.minute)}';
  }

  /// From the accepted offer, before `job_queued` arrives.
  factory QueuedNextRide.fromOffer(NextRideOffer o) => QueuedNextRide(
    jobId: o.jobId,
    pickupAddress: o.job.pickupAddress,
    job: o.job,
  );
}

/// The job JSON of an offer frame (`{job}` top-level or under `data`).
Object? offerJobJson(Map<String, dynamic> raw, Map<String, dynamic>? data) =>
    raw['job'] ?? data?['job'] ?? data ?? raw;

/// How an offer frame is shown.
enum OfferPresentation {
  /// The full incoming-job screen.
  fullScreen,

  /// The compact next-ride card over the live trip — never the full screen.
  nextRideCard,

  /// Not an offer this handles.
  none,
}

/// `job_offer_next`, or a `job_offer` / `scheduled_job_offer` whose job
/// carries `next_offer` (re-sent after a reconnect), is a next ride.
OfferPresentation offerPresentationOf(String type, Object? jobJson) {
  if (type == nextOfferFrameType) return OfferPresentation.nextRideCard;
  if (type != 'job_offer' && type != 'scheduled_job_offer') {
    return OfferPresentation.none;
  }
  return isNextRideOffer(jobJson)
      ? OfferPresentation.nextRideCard
      : OfferPresentation.fullScreen;
}

/// A [NextRideOffer] from an offer's job JSON, or null when it doesn't parse.
/// The window is the job's `timeout_seconds` (the app's default 16 s — the
/// same countdown the full offer uses).
NextRideOffer? nextRideOfferFromJob(Object? jobJson, {required DateTime now}) {
  if (jobJson is! Map) return null;
  final map = Map<String, dynamic>.from(jobJson);
  if (map['id'] == null) return null;
  try {
    final job = IncomingJobModel.fromJson(map);
    final total = job.timeoutSeconds > 0 ? job.timeoutSeconds : 16;
    return NextRideOffer(
      job: job,
      info:
          NextOfferInfo.fromJson(map['next_offer']) ??
          const NextOfferInfo(
            afterJobId: '',
            etaToDropoffMin: 0,
            etaToPickupMin: 0,
          ),
      expiresAt: now.add(Duration(seconds: total)),
      totalSeconds: total,
    );
  } catch (_) {
    return null;
  }
}

/// `job_queued` {job_id, job, arrive_by}, fields top-level or under `data`.
QueuedNextRide? queuedFromFrame(
  Map<String, dynamic> raw,
  Map<String, dynamic>? data,
) {
  Object? read(String k) => raw[k] ?? data?[k];
  final job = read('job');
  final id =
      read('job_id')?.toString() ?? (job is Map ? job['id']?.toString() : null);
  if (id == null || id.isEmpty) return null;
  return _queued(id, job, read('arrive_by'));
}

/// GET /api/driver/jobs/next: the ride with `queued_next.arrive_by`.
QueuedNextRide? queuedFromNextRide(Object? body) {
  if (body is! Map) return null;
  final job = body['job'] is Map ? body['job'] : body;
  if (job is! Map) return null;
  final id = job['id']?.toString();
  if (id == null || id.isEmpty) return null;
  final qn = job['queued_next'];
  return _queued(
    id,
    job,
    qn is Map ? qn['arrive_by'] : null,
    etaMin: qn is Map ? _int(qn['eta_min']) : null,
  );
}

QueuedNextRide _queued(
  String id,
  Object? job,
  Object? arriveBy, {
  int? etaMin,
}) {
  IncomingJobModel? model;
  if (job is Map) {
    try {
      model = IncomingJobModel.fromJson(Map<String, dynamic>.from(job));
    } catch (_) {}
  }
  final pickup =
      model?.pickupAddress ??
      (job is Map ? job['pickup_address']?.toString() : null) ??
      '';
  return QueuedNextRide(
    jobId: id,
    pickupAddress: pickup,
    job: model,
    arriveBy: DateTime.tryParse(arriveBy?.toString() ?? ''),
    etaMin: etaMin,
  );
}

/// Whether a `job_accepted` is the queued next ride starting as the trip
/// completed: the ride queued, or — the queue unknown here (e.g. its read
/// failed after a restart) — another ride accepted while the driver is
/// collecting the fare of the one on screen, which only a back-to-back ride
/// can be.
bool isNextRideStart({
  required String acceptedJobId,
  required bool queued,
  required bool collecting,
  required String? currentJobId,
}) =>
    queued ||
    (collecting && currentJobId != null && currentJobId != acceptedJobId);

/// `job_unqueued` {job_id, reason}.
({String jobId, String reason})? unqueuedFromFrame(
  Map<String, dynamic> raw,
  Map<String, dynamic>? data,
) {
  Object? read(String k) => raw[k] ?? data?[k];
  final id = read('job_id')?.toString();
  if (id == null || id.isEmpty) return null;
  return (jobId: id, reason: read('reason')?.toString() ?? '');
}

/// What the driver reads when the queued ride is taken off their queue
/// (BE internal/job/matching/backtoback.go Unqueued*).
String unqueuedReasonMessage(String reason) => switch (reason) {
  'timeout' => 'งานถัดไปถูกส่งให้คนขับคนอื่น เพราะไปถึงจุดรับไม่ทันเวลา',
  'driver_released' => 'ยกเลิกงานถัดไปแล้ว',
  'trip_ended' => 'งานถัดไปถูกยกเลิก เพราะงานที่ทำอยู่สิ้นสุดลง',
  'cash_blocked' => 'งานถัดไปถูกยกเลิก เพราะเครดิตไม่พอสำหรับงานเงินสด',
  'cancelled' => 'ผู้โดยสารยกเลิกงานถัดไปแล้ว',
  _ => 'งานถัดไปถูกยกเลิกแล้ว',
};

int? _int(Object? v) => v is num
    ? v.round()
    : (v is String ? num.tryParse(v.trim())?.round() : null);
