import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/services/job_cancellation.dart';
import 'package:massdrive/core/services/push_notification_service.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/incoming_job/presentation/controllers/incoming_job_controller.dart';
import 'package:massdrive/features/job_live/domain/repositories/job_live_repository.dart';
import 'package:massdrive/features/messenger/presentation/controllers/messenger_controller.dart';
import 'package:massdrive/router/app_routes.dart';

/// Screens that show a job the driver has accepted.
const _liveJobRoutes = {'/job-live', AppRoutes.foodLiveNamedPage};

/// App-root listener (BE #191): when the job the driver is on is cancelled —
/// by the customer, an admin or the system — close the job screen, say who
/// cancelled it and go back to waiting for jobs. Never retries.
///
/// Also re-checks the job with the backend when the app comes back from the
/// background, since a cancellation may have arrived while the WS was down.
class JobCancelListener extends ConsumerStatefulWidget {
  const JobCancelListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<JobCancelListener> createState() => _JobCancelListenerState();
}

class _JobCancelListenerState extends ConsumerState<JobCancelListener>
    with WidgetsBindingObserver {
  StreamSubscription<JobCancelEvent>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = JobCancellations.instance.events.listen(_onCancelled);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  String get _path =>
      AppRouter.router.routerDelegate.currentConfiguration.uri.path;

  void _onCancelled(JobCancelEvent e) {
    final current = ref.read(incomingJobControllerProvider).currentJob;
    // Only the job the driver is on. Without a job in memory, act only when a
    // live job screen is showing (e.g. state lost to a restart).
    if (current != null
        ? current.jobId != e.jobId
        : !_liveJobRoutes.contains(_path)) {
      return;
    }
    final food = current?.isFood ?? _path == AppRoutes.foodLiveNamedPage;

    ref.read(incomingJobControllerProvider.notifier).dismissModal();
    PushNotificationService.instance.cancelJobAlerts();
    AppRouter.router.go(AppRoutes.homeNamedPage);
    if (e.closedByAdmin) {
      showJobEndedDialog(jobClosedByAdminTitle, jobClosedByAdminMessage);
    } else {
      showJobEndedDialog(
        'งานถูกยกเลิก',
        '${e.message ?? jobCancelledMessage(e.cancelledBy, food: food)}\n'
            'กลับไปรอรับงานใหม่ได้เลย',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_path == '/messenger-live') {
      // A parcel the back office forced to an end while we were away.
      ref.read(messengerControllerProvider.notifier).recheckActive();
    } else {
      _recheckJob();
    }
  }

  /// Back from the background on a live job screen: if the backend no longer
  /// lists the job as active, it ended while we weren't listening: closed by
  /// the back office (the ride reads COMPLETED) or, otherwise, cancelled.
  /// (Not on the collect screen — there the job ends by the driver's hand.)
  Future<void> _recheckJob() async {
    final current = ref.read(incomingJobControllerProvider).currentJob;
    if (current == null || !_liveJobRoutes.contains(_path)) return;
    try {
      final repo = getIt<JobLiveRepository>();
      final active = await repo.getActiveSummary();
      if (!mounted || active.any((a) => a.id == current.jobId)) return;
      final status = current.isFood
          ? null
          : await repo.getJobStatus(current.jobId);
      if (!mounted) return;
      JobCancellations.instance.report(
        JobCancelEvent(current.jobId, closedByAdmin: status == 'COMPLETED'),
      );
    } catch (_) {
      // Offline or the probe failed: keep the job; the WS / push will tell us.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The one-button dialog shown when the job on screen ended without the
/// driver (cancelled, or closed by the back office), after the screen has
/// gone back home.
void showJobEndedDialog(String title, String message) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final ctx = AppRouter.rootContext;
    if (ctx == null || !ctx.mounted) return;
    showDialog<void>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  });
}
