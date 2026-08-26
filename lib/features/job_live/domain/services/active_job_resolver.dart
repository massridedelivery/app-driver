import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/incoming_job/presentation/controllers/incoming_job_controller.dart';
import 'package:massdrive/features/job_live/domain/models/active_item.dart';
import 'package:massdrive/features/job_live/domain/repositories/job_live_repository.dart';
import 'package:massdrive/features/messenger/domain/models/messenger_offer.dart';
import 'package:massdrive/features/messenger/domain/repositories/messenger_repository.dart';
import 'package:massdrive/features/messenger/presentation/controllers/messenger_controller.dart';

/// Where to resume after finding the driver's in-progress job.
class ActiveJobResume {
  final String route;
  final Object? extra;
  const ActiveJobResume(this.route, {this.extra});
}

/// Resolves the driver's current active job (or a pending pre-accept offer),
/// primes the relevant controller state, and returns the screen to navigate to
/// — WITHOUT touching navigation or a BuildContext. Returns `null` when there
/// is nothing to resume.
///
/// This is the single source of truth for "does the driver have a job to go
/// back to?", shared by the app-startup guard (runs on every cold launch, so a
/// killed-and-reopened app always lands back on the live job) and HomeScreen's
/// status probe.
Future<ActiveJobResume?> resolveActiveJob(Ref ref) async {
  final repo = getIt<JobLiveRepository>();

  double? lat;
  double? lng;
  try {
    final position = await Geolocator.getLastKnownPosition() ??
        await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 3),
        );
    lat = position.latitude;
    lng = position.longitude;
  } catch (e) {
    if (kDebugMode) debugPrint('resolveActiveJob: location unavailable: $e');
  }

  // Probe the cross-vertical index once (SCRUM-45) rather than firing every
  // per-vertical endpoint and guessing which one wins.
  final active = await repo.getActiveSummary();

  if (active.isEmpty) {
    // No accepted job — recover a pending (pre-accept) offer if one exists.
    // Cross-vertical now (dev15): ride/food/messenger via the typed response.
    final offer = await repo.getActiveOffer(lat: lat, lng: lng);
    final route = applyRecoveredOffer(ref, offer);
    return route == null ? null : ActiveJobResume(route);
  }

  // Driver holds 0–1 active items; the list is newest-first.
  final item = active.first;
  if (kDebugMode) {
    debugPrint('resolveActiveJob: active ${item.type} (${item.status})');
  }

  // Messenger has its own model/screen.
  if (item.type == ActiveJobType.messenger) {
    final order = await getIt<MessengerRepository>().getActiveOrder();
    if (order == null) return null;
    ref.read(messengerControllerProvider.notifier).setActiveOrder(order);
    return const ActiveJobResume('/messenger-live');
  }

  dynamic detail;
  switch (item.type) {
    case ActiveJobType.ride:
      detail = await repo.getActiveJob(lat: lat, lng: lng);
      break;
    case ActiveJobType.food:
      detail = await repo.getActiveFoodOrder(lat: lat, lng: lng);
      break;
    case ActiveJobType.messenger:
    case ActiveJobType.unknown:
      return null;
  }

  final jobJson = _extractJobJson(detail);
  if (jobJson == null) return null;

  final job = IncomingJobModel.fromJson(jobJson);
  ref.read(incomingJobControllerProvider.notifier).resumeJob(job);

  if (item.type == ActiveJobType.food) {
    return const ActiveJobResume(AppRoutes.foodLiveNamedPage);
  }
  // Hand the vertical status to the live screen so it resumes at the correct
  // trip stage instead of restarting at pickup.
  return ActiveJobResume('/job-live', extra: item.status);
}

/// Extracts the job/order JSON from a per-vertical detail response, which may be
/// a bare object, a `{ "job": {...} }` wrapper, or a list.
/// A pending offer parsed out of `/api/driver/active-offer`, ready to be pushed
/// into whichever controller owns that vertical.
class RecoveredOffer {
  /// Screen that should be showing this offer.
  final String route;

  /// Ride / food offers ride on [IncomingJobModel]; messenger has its own model.
  final IncomingJobModel? job;
  final MessengerOffer? messenger;

  const RecoveredOffer({required this.route, this.job, this.messenger});
}

/// Parse the typed `/api/driver/active-offer` response (dev15):
/// `{ type: ride|food|messenger, <type>: {…} }`.
///
/// Pure — it holds no [Ref] — so the offer screens can reuse it with the
/// `WidgetRef` they have, which is not a [Ref]. Returns null when the payload
/// carries no usable offer.
RecoveredOffer? parseRecoveredOffer(dynamic offer) {
  if (offer is! Map) return null;
  final map = Map<String, dynamic>.from(offer);
  final type = map['type']?.toString();

  if (type == 'messenger') {
    final m = map['messenger'];
    if (m is Map) {
      return RecoveredOffer(
        route: '/messenger-offer',
        messenger: MessengerOffer.fromJson(Map<String, dynamic>.from(m)),
      );
    }
    return null;
  }

  // ride / food both use IncomingJobModel + the incoming-job screen. Fall back
  // to the old flat shape if `type` is absent.
  final vertical = (type != null ? map[type] : null) ??
      map['ride'] ??
      map['food'] ??
      map;
  final json = _extractJobJson(vertical);
  if (json != null) {
    return RecoveredOffer(
      route: AppRoutes.incomingJobNamedPage,
      job: IncomingJobModel.fromJson(json),
    );
  }
  return null;
}

/// Loads a recovered offer into the matching controller and returns the route
/// to open (null if there's none). Shared by the app-startup resolver and
/// HomeScreen's status probe.
String? applyRecoveredOffer(Ref ref, dynamic offer) {
  final recovered = parseRecoveredOffer(offer);
  if (recovered == null) return null;

  if (recovered.messenger != null) {
    ref
        .read(messengerControllerProvider.notifier)
        .receiveOffer(recovered.messenger!);
  } else if (recovered.job != null) {
    ref.read(incomingJobControllerProvider.notifier).receiveJob(recovered.job!);
  }
  return recovered.route;
}

Map<String, dynamic>? _extractJobJson(dynamic data) {
  if (data is Map<String, dynamic>) {
    final job = data['job'];
    if (job is Map<String, dynamic>) return job;
    return data;
  }
  if (data is List && data.isNotEmpty) {
    final first = data.first;
    if (first is Map<String, dynamic>) return first;
  }
  return null;
}
