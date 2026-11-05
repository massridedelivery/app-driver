import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/referral/data/referral_api.dart';
import 'package:massdrive/features/referral/domain/driver_referral.dart';

final referralApiProvider = Provider<ReferralApi>(
  (ref) => ReferralApi(ref.watch(dioProvider)),
);

/// `GET /api/driver/referral`, fetched fresh on every visit. Errors surface
/// to the invite screen; entry points ([referralEnabledProvider]) treat
/// them as "hidden".
final driverReferralProvider = FutureProvider.autoDispose<ReferralInfo>((ref) {
  // A bonus was paid meanwhile: statuses and the summary changed.
  void onPaid() => ref.invalidateSelf();
  ReferralUpdates.instance.addListener(onPaid);
  ref.onDispose(() => ReferralUpdates.instance.removeListener(onPaid));
  return ref.watch(referralApiProvider).get();
});

/// The info when the program is on, null otherwise (off, loading, error).
final referralEnabledProvider = Provider.autoDispose<ReferralInfo?>((ref) {
  final info = ref.watch(driverReferralProvider).asData?.value;
  return info != null && info.enabled ? info : null;
});
