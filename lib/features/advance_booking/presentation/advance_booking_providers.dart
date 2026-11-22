import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/core/services/location_service.dart';
import 'package:massdrive/features/advance_booking/data/advance_booking_api.dart';
import 'package:massdrive/features/advance_booking/domain/advance_eligibility.dart';
import 'package:massdrive/features/advance_booking/domain/advance_errors.dart';
import 'package:massdrive/features/advance_booking/domain/advance_pushes.dart';
import 'package:massdrive/features/advance_booking/domain/advance_ride.dart';
import 'package:massdrive/features/dependency_injection.dart';

final advanceBookingApiProvider = Provider<AdvanceBookingApi>(
  (ref) => AdvanceBookingApi(ref.watch(dioProvider)),
);

/// A refusal (403 board off, …) won't change by asking again; a network
/// blip is retried a few times.
Duration? _retry(int count, Object error) =>
    error is AdvanceBookingException || count >= 3
    ? null
    : Duration(seconds: 1 << count);

/// Re-read whenever an advance booking push arrives.
void _refreshOnPush(Ref ref) {
  void onPush() => ref.invalidateSelf();
  AdvanceBookingUpdates.instance.addListener(onPush);
  ref.onDispose(() => AdvanceBookingUpdates.instance.removeListener(onPush));
}

/// The admin switch (`GET /api/driver/advance-booking/config`). False while
/// loading and on any error, so every entry point stays hidden.
final advanceBookingEnabledProvider = FutureProvider.autoDispose<bool>((ref) {
  _refreshOnPush(ref);
  return ref.watch(advanceBookingApiProvider).enabled();
});

final advanceEligibilityProvider =
    FutureProvider.autoDispose<AdvanceEligibility>((ref) {
      _refreshOnPush(ref);
      return ref.watch(advanceBookingApiProvider).eligibility();
    }, retry: _retry);

/// The board for one Bangkok day (null: everything ahead), around the
/// driver's position when there is a fix (no fix: the whole board, without
/// distance_from_you_km).
final advanceBoardProvider = FutureProvider.autoDispose
    .family<List<AdvanceRide>, DateTime?>((ref, day) async {
      _refreshOnPush(ref);
      final api = ref.watch(advanceBookingApiProvider);
      final at = await ref.read(locationServiceProvider).currentPosition();
      return api.board(lat: at?.latitude, lng: at?.longitude, day: day);
    }, retry: _retry);

/// "งานของฉัน".
final advanceMineProvider = FutureProvider.autoDispose<List<AdvanceRide>>((
  ref,
) {
  _refreshOnPush(ref);
  return ref.watch(advanceBookingApiProvider).mine();
}, retry: _retry);

/// After a claim / release / start: every list changed.
void invalidateAdvanceLists(WidgetRef ref) {
  ref.invalidate(advanceBoardProvider);
  ref.invalidate(advanceMineProvider);
  ref.invalidate(advanceEligibilityProvider);
}
