import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/incoming_job/presentation/controllers/incoming_job_controller.dart';
import 'package:massdrive/router/app_routes.dart';

/// After "กำลังไป" succeeded: the backend accepted the ride for the driver
/// like an offer (job_accepted follows on the socket, which only stores the
/// job). Load it from GET /api/driver/jobs/active and open the live screen
/// the way an accepted offer does. When it can't be read yet, home shows it
/// in the active-job banner. Returns whether the live screen opened.
Future<bool> openStartedAdvanceRide(WidgetRef ref, String jobId) async {
  final jobs = ref.read(incomingJobControllerProvider.notifier);
  IncomingJobModel? held;
  for (var attempt = 0; attempt < 3; attempt++) {
    if (attempt > 0) await Future<void>.delayed(const Duration(seconds: 2));
    final fresh = await jobs.refreshActiveJob();
    if (fresh?.jobId == jobId) {
      held = fresh;
      break;
    }
  }
  if (held == null) {
    AppRouter.router.go(AppRoutes.homeNamedPage);
    return false;
  }
  jobs.resumeJob(held);
  AppRouter.router.go('/job-live');
  return true;
}
