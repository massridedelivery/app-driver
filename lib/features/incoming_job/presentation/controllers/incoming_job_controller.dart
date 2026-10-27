import 'package:massdrive/features/income/domain/models/cash_job_gate.dart';
import 'package:massdrive/features/income/presentation/controllers/wallet_controller.dart';
import 'package:massdrive/features/income/presentation/widgets/credit_notice_dialog.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/services/push_notification_service.dart';
import 'package:massdrive/core/services/socket_service.dart';
import 'package:massdrive/features/incoming_job/data/sources/food_delivery_api_service.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/incoming_job/presentation/states/incoming_job_state.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/router/app_routes.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:massdrive/core/services/job_cancellation.dart';
import 'package:massdrive/features/incoming_job/domain/accept_outcome.dart';
import 'package:massdrive/features/job_live/domain/repositories/job_live_repository.dart';
import 'package:flutter/material.dart';
import 'package:massdrive/features/job_live/domain/services/active_job_resolver.dart';

part 'incoming_job_controller.g.dart';

@Riverpod(keepAlive: true)
class IncomingJobController extends _$IncomingJobController {
  StreamSubscription? _socketSubscription;

  @override
  IncomingJobState build() {
    final socket = ref.watch(socketServiceProvider);

    _socketSubscription?.cancel();
    _socketSubscription = socket.messages.listen((msg) {
      if (kDebugMode) {
        debugPrint('IncomingJobController Received Message: type=${msg.type}');
      }

      if (msg.type == 'job_offer') {
        if (kDebugMode) debugPrint('IncomingJobController: 📥 RECEIVED job_offer message');
        _handleJobOffer(msg.raw, msg.data);
      } else if (msg.type == 'food_delivery_offer') {
        if (kDebugMode) {
          debugPrint(
            'IncomingJobController: 🍔 RECEIVED food_delivery_offer message',
          );
        }
        _handleFoodDeliveryOffer(msg.raw, msg.data);
      } else if (msg.type == 'job_accepted') {
        // Notification that the job is confirmed to us
        try {
          final jobData =
              msg.raw['job'] ?? msg.data?['job'] ?? msg.data ?? msg.raw;
          if (jobData is Map<String, dynamic>) {
            final job = IncomingJobModel.fromJson(jobData);
            state = state.copyWith(currentJob: job);
            if (kDebugMode) {
              debugPrint(
                'IncomingJobController: Job officially accepted: ${job.jobId}',
              );
            }
          }
        } catch (e) {
          if (kDebugMode) debugPrint('IncomingJobController Parse Error (job_accepted): $e');
        }
      } else if (jobCancelFromSocket(msg.type, msg.raw, msg.data)
          case final cancel?) {
        // The app-root JobCancelListener closes the job screen and tells the
        // driver who cancelled (BE #191).
        if (kDebugMode) debugPrint('IncomingJobController: cancelled ${cancel.jobId}');
        JobCancellations.instance.report(cancel);
      }
    });

    ref.onDispose(() {
      _socketSubscription?.cancel();
    });

    return const IncomingJobState();
  }

  /// Handle ride job_offer event
  void _handleJobOffer(
    Map<String, dynamic> raw,
    Map<String, dynamic>? data,
  ) {
    try {
      final jobData = raw['job'] ?? data?['job'] ?? data ?? raw;
      if (kDebugMode) debugPrint('IncomingJobController: Job Data extracted: $jobData');

      if (jobData is Map<String, dynamic> && jobData.containsKey('id')) {
        final job = IncomingJobModel.fromJson(jobData);
        if (kDebugMode) {
          debugPrint(
            'IncomingJobController: ✅ Ride Job parsed. ID=${job.jobId}',
          );
        }

        receiveJob(job);
        // Ring the loud alert locally — the offer arrived over the WebSocket,
        // which carries no sound of its own. De-duped against any FCM push.
        PushNotificationService.instance.alertJobOffer(key: job.jobId);
        AppRouter.router.go(AppRoutes.incomingJobNamedPage);
      } else {
        if (kDebugMode) {
          debugPrint(
            'IncomingJobController: ⚠️ job_offer data invalid. Data: $jobData',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('IncomingJobController: ❌ Parse Error (job_offer): $e');
    }
  }

  /// Handle food_delivery_offer event
  void _handleFoodDeliveryOffer(
    Map<String, dynamic> raw,
    Map<String, dynamic>? data,
  ) {
    try {
      final jobData = raw['order'] ?? data?['order'] ?? data ?? raw;
      if (kDebugMode) {
        debugPrint(
          'IncomingJobController: Food Order Data extracted: $jobData',
        );
      }

      if (jobData is Map<String, dynamic> && jobData.containsKey('id')) {
        // Ensure service_type marks it as food if not already set
        final enrichedData = Map<String, dynamic>.from(jobData);
        enrichedData['service_type'] ??= 'MassFood';

        final job = IncomingJobModel.fromJson(enrichedData);
        if (kDebugMode) {
          debugPrint(
            'IncomingJobController: 🍔 Food Job parsed. ID=${job.jobId}, '
            'restaurant=${job.restaurantName}, items=${job.orderItems.length}',
          );
        }

        receiveJob(job);
        // Ring the loud alert locally — the offer arrived over the WebSocket,
        // which carries no sound of its own. De-duped against any FCM push.
        PushNotificationService.instance.alertJobOffer(key: job.jobId);
        AppRouter.router.go(AppRoutes.incomingJobNamedPage);
      } else {
        if (kDebugMode) {
          debugPrint(
            'IncomingJobController: ⚠️ food_delivery_offer data invalid. Data: $jobData',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'IncomingJobController: ❌ Parse Error (food_delivery_offer): $e',
        );
      }
    }
  }

  void receiveJob(IncomingJobModel job) {
    state = state.copyWith(currentJob: job, isModalVisible: true);
  }

  void resumeJob(IncomingJobModel job) {
    state = state.copyWith(currentJob: job, isModalVisible: false);
  }

  /// Fresh copy of the job the driver is on from GET /api/driver/jobs/active
  /// (driver_earnings, amount_due and its parts change during the trip —
  /// never keep the offer's). Null when there's no active job or it failed.
  Future<IncomingJobModel?> refreshActiveJob() async {
    final current = state.currentJob;
    try {
      final detail = await getIt<JobLiveRepository>().getActiveJob();
      final json = extractJobJson(detail);
      if (json == null) return null;
      final fresh = IncomingJobModel.fromJson(json);
      if (current == null || current.jobId == fresh.jobId) {
        state = state.copyWith(currentJob: fresh);
      }
      return fresh;
    } catch (e) {
      if (kDebugMode) debugPrint('IncomingJobController: refresh failed $e');
      return null;
    }
  }

  /// Accept a ride job via WebSocket
  /// Accept the ride on offer via POST /api/driver/jobs/:id/accept (BE #198)
  /// and open the live screen only once the backend says it's ours.
  ///
  /// - 200 → accepted (a repeat by this driver is also 200).
  /// - 409 `job_taken` → someone else got it: close the offer, "มีคนรับงานนี้
  ///   ไปแล้ว" — never "งานถูกยกเลิก".
  /// - Anything else / timeout → ask GET /api/driver/jobs/active whether we hold
  ///   it after all; if not, the driver can try again.
  Future<AcceptOutcome> acceptJob() async {
    // Stop the ~10s job-alert notification sound the moment the driver acts.
    PushNotificationService.instance.cancelJobAlerts();
    final job = state.currentJob;
    if (job == null) {
      state = state.copyWith(isModalVisible: false);
      return AcceptOutcome.failed;
    }

    final repo = getIt<JobLiveRepository>();
    var outcome = AcceptOutcome.failed;
    try {
      await repo.acceptJob(job.jobId);
      outcome = AcceptOutcome.accepted;
    } catch (e) {
      if (isJobTakenError(e)) {
        outcome = AcceptOutcome.taken;
      } else if (isCashJobBlockedError(e)) {
        outcome = AcceptOutcome.cashBlocked;
      } else {
        // Timeout / network error: GET /api/driver/jobs/active decides.
        final held = await refreshActiveJob();
        if (held?.jobId == job.jobId) outcome = AcceptOutcome.accepted;
      }
      if (kDebugMode) debugPrint('IncomingJobController: accept $outcome ($e)');
    }

    switch (outcome) {
      case AcceptOutcome.accepted:
        _sendLocationUpdate();
        state = state.copyWith(isModalVisible: false);
        final isFood = job.serviceType.toLowerCase().contains('food');
        AppRouter.router.go(isFood ? AppRoutes.foodLiveNamedPage : '/job-live');
      case AcceptOutcome.taken:
        dismissModal();
        _toast(acceptOutcomeMessage(outcome));
      case AcceptOutcome.cashBlocked:
        dismissModal();
        _showCashBlocked();
      case AcceptOutcome.failed:
        _toast(acceptOutcomeMessage(outcome));
    }
    return outcome;
  }

  /// Cash job refused for the cash-job limit: refresh the gate (home card)
  /// and explain, with "เติมเครดิต".
  Future<void> _showCashBlocked() async {
    final gate = await ref
        .read(walletControllerProvider.notifier)
        .fetchPayoutSummary();
    final ctx = AppRouter.rootContext;
    if (ctx == null || !ctx.mounted) return;
    await showCashJobBlockedDialog(ctx, gate);
  }

  void _toast(String message) {
    final ctx = AppRouter.rootContext;
    if (ctx == null || !ctx.mounted) return;
    ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Accept a food delivery job via REST API. A 403 for the cash-job limit
  /// closes the offer and explains; any other failure lets the driver retry.
  Future<AcceptOutcome> acceptFoodJob() async {
    PushNotificationService.instance.cancelJobAlerts();
    final job = state.currentJob;
    if (job == null) return AcceptOutcome.failed;

    try {
      final apiService = getIt<FoodDeliveryApiService>();
      await apiService.acceptOrder(job.jobId);
      if (kDebugMode) {
        debugPrint(
          'IncomingJobController: 🍔 Food job accepted via REST API: ${job.jobId}',
        );
      }
      _sendLocationUpdate();
      
      state = state.copyWith(isModalVisible: false);
      AppRouter.router.go(AppRoutes.foodLiveNamedPage);
      return AcceptOutcome.accepted;
    } catch (e) {
      if (kDebugMode) debugPrint('IncomingJobController: ❌ Failed to accept food job: $e');
      if (isCashJobBlockedError(e)) {
        dismissModal();
        _showCashBlocked();
        return AcceptOutcome.cashBlocked;
      }
      _toast(acceptOutcomeMessage(AcceptOutcome.failed));
      return AcceptOutcome.failed;
    }
  }

  void declineJob() {
    PushNotificationService.instance.cancelJobAlerts();
    final job = state.currentJob;
    if (job != null) {
      ref.read(socketServiceProvider).rejectJob(job.jobId);
      _sendLocationUpdate();
    }
    state = state.copyWith(isModalVisible: false, currentJob: null);
    // '/' matches no route: it lands in the router's error state, which only
    // *looks* right because errorBuilder renders HomeScreen.
    AppRouter.router.go(AppRoutes.homeNamedPage);
  }

  /// Decline a food delivery offer via REST. Food orders live in a separate
  /// backend service with their own reject endpoint (POST .../orders/:id/reject
  /// to release the offer lock) — the WS `reject_job` used by [declineJob] only
  /// touches the ride dispatcher, so a food decline must go through here.
  Future<void> declineFoodJob() async {
    PushNotificationService.instance.cancelJobAlerts();
    final job = state.currentJob;
    state = state.copyWith(isModalVisible: false, currentJob: null);
    if (job != null) {
      try {
        await getIt<FoodDeliveryApiService>().rejectOrder(job.jobId);
      } catch (e) {
        // Best-effort: the offer still disappears client-side and the server
        // lock expires on its own; don't strand the driver on a failure.
        if (kDebugMode) {
          debugPrint('IncomingJobController: ❌ Failed to reject food job: $e');
        }
      }
    }
    AppRouter.router.go(AppRoutes.homeNamedPage);
  }

  void dismissModal() {
    state = state.copyWith(isModalVisible: false, currentJob: null);
    _sendLocationUpdate();
  }

  Future<void> _sendLocationUpdate() async {
    try {
      final socketService = ref.read(socketServiceProvider);
      if (socketService.isConnected) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        socketService.sendLocationUpdate(position.latitude, position.longitude);
        if (kDebugMode) {
          debugPrint(
            'IncomingJobController: Sent location_update after job flow',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('IncomingJobController: Error sending location update: $e');
    }
  }
}
