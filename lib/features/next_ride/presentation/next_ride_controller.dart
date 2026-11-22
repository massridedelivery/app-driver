import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/core/services/push_notification_service.dart';
import 'package:massdrive/core/services/socket_service.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/income/domain/models/cash_job_gate.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/job_live/domain/repositories/job_live_repository.dart';
import 'package:massdrive/features/job_live/domain/services/active_job_resolver.dart';
import 'package:massdrive/features/next_ride/data/next_ride_api_service.dart';
import 'package:massdrive/features/next_ride/domain/next_ride.dart';
import 'package:massdrive/router/app_routes.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'next_ride_controller.g.dart';

/// The next-ride card and banner over the live trip.
@immutable
class NextRideState {
  const NextRideState({
    this.offer,
    this.accepting = false,
    this.queued,
    this.started,
  });

  /// A next-ride offer waiting for the driver (the compact card).
  final NextRideOffer? offer;

  /// The accept of [offer] is in flight.
  final bool accepting;

  /// The ride queued as the driver's next one (the banner).
  final QueuedNextRide? queued;

  /// The queued ride's `job_accepted`, held while the collect screen is still
  /// completing the trip; it opens the ride once its COMPLETED goes through.
  final IncomingJobModel? started;

  NextRideState copyWith({
    NextRideOffer? Function()? offer,
    bool? accepting,
    QueuedNextRide? Function()? queued,
    IncomingJobModel? Function()? started,
  }) => NextRideState(
    offer: offer != null ? offer() : this.offer,
    accepting: accepting ?? this.accepting,
    queued: queued != null ? queued() : this.queued,
    started: started != null ? started() : this.started,
  );
}

/// What [NextRideController] does outside its state: sockets, sounds, toasts
/// and the reads it reconciles with. Replaced in tests.
abstract class NextRideEffects {
  /// WS `reject_job` for a declined or lapsed offer.
  void reject(String jobId);

  /// The loud offer alert, as for a normal offer.
  void ring(String jobId);

  void stopRinging();

  void toast(String message);

  /// GET /api/driver/jobs/active: the ride the driver holds now, or null.
  Future<IncomingJobModel?> activeRide();

  /// GET /api/driver/active-offer: the pending offer's job JSON, or null.
  Future<Map<String, dynamic>?> activeOfferJob();
}

class AppNextRideEffects implements NextRideEffects {
  AppNextRideEffects(this._ref);

  final Ref _ref;

  @override
  void reject(String jobId) =>
      _ref.read(socketServiceProvider).rejectJob(jobId);

  @override
  void ring(String jobId) => PushNotificationService.instance.alertJobOffer(
    key: jobId,
    title: 'มีงานถัดไปใกล้จุดส่ง',
    body: 'รับไว้แล้วจะเริ่มทันทีเมื่อส่งผู้โดยสารเสร็จ',
  );

  @override
  void stopRinging() => PushNotificationService.instance.cancelJobAlerts();

  @override
  void toast(String message) {
    final ctx = AppRouter.rootContext;
    if (ctx == null || !ctx.mounted) return;
    ScaffoldMessenger.maybeOf(
      ctx,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Future<IncomingJobModel?> activeRide() async {
    try {
      final json = extractJobJson(
        await getIt<JobLiveRepository>().getActiveJob(),
      );
      return json == null ? null : IncomingJobModel.fromJson(json);
    } catch (e) {
      if (kDebugMode) debugPrint('NextRide: active ride read failed: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> activeOfferJob() async {
    try {
      final offer = await getIt<JobLiveRepository>().getActiveOffer();
      if (offer is! Map) return null;
      final type = offer['type']?.toString();
      final vertical =
          (type != null ? offer[type] : null) ?? offer['ride'] ?? offer;
      return extractJobJson(vertical);
    } catch (e) {
      if (kDebugMode) debugPrint('NextRide: active offer read failed: $e');
      return null;
    }
  }
}

final nextRideApiProvider = Provider<NextRideApiService>(
  (ref) => getIt<NextRideApiService>(),
);

final nextRideEffectsProvider = Provider<NextRideEffects>(
  (ref) => AppNextRideEffects(ref),
);

/// Back-to-back rides (งานต่อเนื่อง): the next-ride offer, the queued ride,
/// and the hand-over to it when the current trip completes.
///
/// offer ─accept→ queued ─(trip COMPLETED: job_accepted)→ started → live
///   │                 └─(job_unqueued / unqueue)→ none, with a toast
///   └─decline / 16 s→ none (WS reject_job)
@Riverpod(keepAlive: true)
class NextRideController extends _$NextRideController {
  Timer? _expiry;
  Completer<void>? _settled;
  Future<NextRideAcceptOutcome>? _inFlight;

  /// Clock for the offer window; replaced in tests.
  @visibleForTesting
  DateTime Function() clock = DateTime.now;

  NextRideApiService get _api => ref.read(nextRideApiProvider);
  NextRideEffects get _fx => ref.read(nextRideEffectsProvider);

  @override
  NextRideState build() {
    ref.onDispose(() => _expiry?.cancel());
    return const NextRideState();
  }

  bool isQueued(String jobId) => state.queued?.jobId == jobId;

  /// A next-ride offer (`job_offer_next`, or an offer carrying `next_offer`):
  /// show the card and ring. A repeat of the offer on screen, or of the ride
  /// already queued, is ignored. Returns whether the card opened.
  bool receiveOffer(Object? jobJson) {
    final offer = nextRideOfferFromJob(jobJson, now: clock());
    if (offer == null) return false;
    if (state.offer?.jobId == offer.jobId || isQueued(offer.jobId)) {
      return false;
    }
    if (state.accepting) return false;
    // A newer offer replaces one still on the card: the backend moved on.
    final previous = state.offer;
    if (previous != null) _fx.reject(previous.jobId);
    state = state.copyWith(offer: () => offer);
    _armExpiry(offer);
    _fx.ring(offer.jobId);
    return true;
  }

  void _armExpiry(NextRideOffer offer) {
    _expiry?.cancel();
    final left = offer.expiresAt.difference(clock());
    _expiry = Timer(left.isNegative ? Duration.zero : left, () {
      if (state.offer?.jobId == offer.jobId && !state.accepting) decline();
    });
  }

  /// "รับงานต่อ": POST /api/driver/jobs/:id/accept → `queued: true` turns the
  /// card into the banner.
  Future<NextRideAcceptOutcome> accept() =>
      _inFlight ??= _accept().whenComplete(() => _inFlight = null);

  Future<NextRideAcceptOutcome> _accept() async {
    final offer = state.offer;
    if (offer == null) return NextRideAcceptOutcome.gone;
    _fx.stopRinging();
    _expiry?.cancel();
    state = state.copyWith(accepting: true);
    final outcome = await _api.accept(offer.jobId);
    if (state.offer?.jobId != offer.jobId) {
      // Replaced, or settled by a frame meanwhile (job_queued can beat the
      // reply).
      state = state.copyWith(accepting: false);
      if (outcome == NextRideAcceptOutcome.queued && isQueued(offer.jobId)) {
        _fx.toast(_queuedToast);
      }
      return outcome;
    }
    switch (outcome) {
      case NextRideAcceptOutcome.queued:
        final q = QueuedNextRide.fromOffer(offer);
        state = state.copyWith(
          offer: () => null,
          accepting: false,
          queued: () => isQueued(q.jobId) ? state.queued!.merge(q) : q,
        );
        _fx.toast(_queuedToast);
      case NextRideAcceptOutcome.unavailable:
        _close();
      case NextRideAcceptOutcome.gone:
        _close();
        _fx.toast('งานนี้ไม่สามารถรับได้แล้ว');
      case NextRideAcceptOutcome.cashBlocked:
        _close();
        _fx.toast(CashJobGate.defaultBlockedMessage);
      case NextRideAcceptOutcome.notQueued:
        // Not what a next-ride accept answers; ask the backend what it holds.
        _close();
        unawaited(refresh());
      case NextRideAcceptOutcome.failed:
        state = state.copyWith(accepting: false);
        if (offer.remainingAt(clock()) <= 0) {
          decline();
        } else {
          _armExpiry(offer);
          _fx.toast('รับงานไม่สำเร็จ กรุณาลองใหม่');
        }
    }
    return outcome;
  }

  static const _queuedToast =
      'รับงานถัดไปแล้ว จะเริ่มทันทีเมื่อส่งผู้โดยสารเสร็จ';

  void _close() => state = state.copyWith(offer: () => null, accepting: false);

  /// "ไม่รับงานนี้", or the window ran out: WS `reject_job` for the ride.
  void decline() {
    final offer = state.offer;
    if (offer == null) return;
    _expiry?.cancel();
    _fx.stopRinging();
    _fx.reject(offer.jobId);
    _close();
  }

  /// WS `job_queued` {job_id, job, arrive_by}.
  void onQueued(Map<String, dynamic> raw, Map<String, dynamic>? data) {
    final q = queuedFromFrame(raw, data);
    if (q == null) return;
    final current = state.queued;
    state = state.copyWith(
      queued: () => current?.jobId == q.jobId ? current!.merge(q) : q,
      offer: state.offer?.jobId == q.jobId ? () => null : null,
      accepting: state.offer?.jobId == q.jobId ? false : null,
    );
  }

  /// WS `job_unqueued` {job_id, reason}: drop the banner and say why.
  void onUnqueued(Map<String, dynamic> raw, Map<String, dynamic>? data) {
    final u = unqueuedFromFrame(raw, data);
    if (u == null) return;
    if (state.offer?.jobId == u.jobId) _close();
    if (!isQueued(u.jobId)) return;
    state = state.copyWith(queued: () => null);
    _fx.toast(unqueuedReasonMessage(u.reason));
    _settle();
  }

  /// The queued ride's `job_accepted`: the trip completed and it started.
  void onQueuedRideStarted(IncomingJobModel job) {
    state = state.copyWith(queued: () => null, started: () => job);
    _settle();
  }

  /// The started ride, once, for whoever opens it.
  IncomingJobModel? takeStarted() {
    final s = state.started;
    if (s != null) state = state.copyWith(started: () => null);
    return s;
  }

  void _settle() {
    final c = _settled;
    _settled = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  /// The collect screen, right after its COMPLETED went through: the ride
  /// that started in the trip's place, or null to carry on as usual (review,
  /// then home). With a ride queued it waits up to [wait] for its
  /// `job_accepted` (or a `job_unqueued`), then asks GET /jobs/active.
  Future<IncomingJobModel?> handOverAfterTrip({
    Duration wait = const Duration(seconds: 4),
  }) async {
    if (state.started == null && state.queued != null) {
      final c = _settled ??= Completer<void>();
      await c.future.timeout(wait, onTimeout: () {});
    }
    if (takeStarted() case final started?) return started;
    final queued = state.queued;
    if (queued == null) return null;
    final active = await _fx.activeRide();
    if (active == null || active.jobId != queued.jobId) return null;
    state = state.copyWith(queued: () => null);
    return active;
  }

  /// Back on the live trip (entry, app resumed): GET /api/driver/jobs/next
  /// for the banner; without one, a next-ride offer still pending for
  /// [onTripJobId] (GET /api/driver/active-offer) reopens the card.
  Future<void> refresh({String? onTripJobId}) async {
    try {
      final body = await _api.getNextRide();
      final q = queuedFromNextRide(body);
      if (q != null) {
        final current = state.queued;
        state = state.copyWith(
          queued: () => current?.jobId == q.jobId ? current!.merge(q) : q,
        );
        return;
      }
      // 404: nothing queued (any more). Not while the trip's end is being
      // handed over: there the ride has just started, and its job_accepted
      // is what settles it.
      if (state.started == null && state.queued != null && _settled == null) {
        state = state.copyWith(queued: () => null);
      }
    } catch (e) {
      // Offline / server error: keep what we have; the WS will tell us.
      if (kDebugMode) debugPrint('NextRide: next ride read failed: $e');
      return;
    }
    if (onTripJobId == null || state.offer != null) return;
    final json = await _fx.activeOfferJob();
    if (!isNextRideOffer(json)) return;
    final after = NextOfferInfo.fromJson(json!['next_offer'])?.afterJobId ?? '';
    if (after.isNotEmpty && after != onTripJobId) return;
    receiveOffer(json);
  }

  /// "ยกเลิกงานถัดไป" (after the driver confirmed): POST /jobs/:id/unqueue.
  /// Returns whether the banner went.
  Future<bool> unqueue() async {
    final q = state.queued;
    if (q == null) return true;
    try {
      await _api.unqueue(q.jobId);
    } catch (e) {
      if (!isNoNextRideError(e)) {
        _fx.toast('ยกเลิกงานถัดไปไม่สำเร็จ กรุณาลองใหม่');
        return false;
      }
      // 404 no_next_ride: it had already gone.
    }
    if (isQueued(q.jobId)) {
      state = state.copyWith(queued: () => null);
      _fx.toast(unqueuedReasonMessage('driver_released'));
      _settle();
    }
    return true;
  }
}
