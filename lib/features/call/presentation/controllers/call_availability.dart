import 'dart:async';

import 'package:massdrive/core/auth/session_notifier.dart';
import 'package:massdrive/features/call/domain/call_error.dart';
import 'package:massdrive/features/call/presentation/controllers/call_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'call_availability.g.dart';

class CallAvailabilityState {
  const CallAvailabilityState({
    this.enabled = false,
    this.notCallable = const {},
  });

  /// `GET /api/calls/settings` → `enabled`. Off until the backend says on.
  final bool enabled;

  /// Orders the backend refused a call for (CALL_NOT_ALLOWED, not ours).
  final Set<String> notCallable;

  bool canCall(String jobId) => enabled && !notCallable.contains(jobId);
}

/// Whether the call button may show: the calling settings, fetched at
/// startup / login and kept for the session, minus orders that were refused.
@Riverpod(keepAlive: true)
class CallAvailability extends _$CallAvailability {
  @override
  CallAvailabilityState build() {
    final session = SessionNotifier.instance;
    void onSession() {
      if (session.isAuthenticated) unawaited(refresh());
    }

    session.addListener(onSession);
    ref.onDispose(() => session.removeListener(onSession));
    if (session.isAuthenticated) Future.microtask(refresh);
    return const CallAvailabilityState();
  }

  Future<void> refresh() async {
    try {
      final settings = await ref.read(callApiProvider).getSettings();
      state = CallAvailabilityState(
        enabled: settings.enabled,
        notCallable: state.notCallable,
      );
    } on CallError catch (_) {
      // Offline / not deployed: keep what we had (off by default).
    }
  }

  void hideFor(String jobId) => state = CallAvailabilityState(
    enabled: state.enabled,
    notCallable: {...state.notCallable, jobId},
  );
}
