// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'next_ride_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Back-to-back rides (งานต่อเนื่อง): the next-ride offer, the queued ride,
/// and the hand-over to it when the current trip completes.
///
/// offer ─accept→ queued ─(trip COMPLETED: job_accepted)→ started → live
///   │                 └─(job_unqueued / unqueue)→ none, with a toast
///   └─decline / 16 s→ none (WS reject_job)

@ProviderFor(NextRideController)
const nextRideControllerProvider = NextRideControllerProvider._();

/// Back-to-back rides (งานต่อเนื่อง): the next-ride offer, the queued ride,
/// and the hand-over to it when the current trip completes.
///
/// offer ─accept→ queued ─(trip COMPLETED: job_accepted)→ started → live
///   │                 └─(job_unqueued / unqueue)→ none, with a toast
///   └─decline / 16 s→ none (WS reject_job)
final class NextRideControllerProvider
    extends $NotifierProvider<NextRideController, NextRideState> {
  /// Back-to-back rides (งานต่อเนื่อง): the next-ride offer, the queued ride,
  /// and the hand-over to it when the current trip completes.
  ///
  /// offer ─accept→ queued ─(trip COMPLETED: job_accepted)→ started → live
  ///   │                 └─(job_unqueued / unqueue)→ none, with a toast
  ///   └─decline / 16 s→ none (WS reject_job)
  const NextRideControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nextRideControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nextRideControllerHash();

  @$internal
  @override
  NextRideController create() => NextRideController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NextRideState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NextRideState>(value),
    );
  }
}

String _$nextRideControllerHash() =>
    r'c6380284748adee7611c761685017d9985de7a9d';

/// Back-to-back rides (งานต่อเนื่อง): the next-ride offer, the queued ride,
/// and the hand-over to it when the current trip completes.
///
/// offer ─accept→ queued ─(trip COMPLETED: job_accepted)→ started → live
///   │                 └─(job_unqueued / unqueue)→ none, with a toast
///   └─decline / 16 s→ none (WS reject_job)

abstract class _$NextRideController extends $Notifier<NextRideState> {
  NextRideState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<NextRideState, NextRideState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NextRideState, NextRideState>,
              NextRideState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
