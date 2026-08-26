import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/incoming_job/presentation/controllers/incoming_job_controller.dart';
import 'package:massdrive/features/job_live/domain/repositories/job_live_repository.dart';
import 'package:massdrive/features/job_live/domain/services/active_job_resolver.dart';
import 'package:massdrive/features/messenger/presentation/controllers/messenger_controller.dart';

/// Pulls the pending offer that a push notification only *pointed at*.
///
/// Job pushes carry no job data — the app is a wake-and-route receiver (see
/// fcm_push_notification_spec.md) — and while the app is backgrounded the
/// WebSocket that normally delivers offers is not connected. So a driver who
/// taps the alert arrives at the offer screen with empty controller state and
/// nothing to accept. This fetches the live offer over REST and primes the same
/// controllers the socket path would have.
///
/// Takes a [WidgetRef] because it is called from screens. Returns the route
/// that should be showing the offer, or null when there is nothing left to
/// show — the offer expired, or another driver took it.
Future<String?> recoverPendingOffer(WidgetRef ref) async {
  double? lat;
  double? lng;
  try {
    final position = await Geolocator.getLastKnownPosition() ??
        await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 3),
          ),
        );
    lat = position.latitude;
    lng = position.longitude;
  } catch (e) {
    // Dispatch can still match the offer without a fresh fix.
    if (kDebugMode) debugPrint('recoverPendingOffer: location unavailable: $e');
  }

  final offer = await getIt<JobLiveRepository>().getActiveOffer(
    lat: lat,
    lng: lng,
  );

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
