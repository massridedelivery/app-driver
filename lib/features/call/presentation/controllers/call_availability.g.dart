// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_availability.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the call button may show: the calling settings, fetched at
/// startup / login and kept for the session, minus orders that were refused.

@ProviderFor(CallAvailability)
const callAvailabilityProvider = CallAvailabilityProvider._();

/// Whether the call button may show: the calling settings, fetched at
/// startup / login and kept for the session, minus orders that were refused.
final class CallAvailabilityProvider
    extends $NotifierProvider<CallAvailability, CallAvailabilityState> {
  /// Whether the call button may show: the calling settings, fetched at
  /// startup / login and kept for the session, minus orders that were refused.
  const CallAvailabilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'callAvailabilityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$callAvailabilityHash();

  @$internal
  @override
  CallAvailability create() => CallAvailability();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CallAvailabilityState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CallAvailabilityState>(value),
    );
  }
}

String _$callAvailabilityHash() => r'724339ee332be2d758010ae5193725963e03fa1f';

/// Whether the call button may show: the calling settings, fetched at
/// startup / login and kept for the session, minus orders that were refused.

abstract class _$CallAvailability extends $Notifier<CallAvailabilityState> {
  CallAvailabilityState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<CallAvailabilityState, CallAvailabilityState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CallAvailabilityState, CallAvailabilityState>,
              CallAvailabilityState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
