// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(callApi)
const callApiProvider = CallApiProvider._();

final class CallApiProvider
    extends $FunctionalProvider<CallApiService, CallApiService, CallApiService>
    with $Provider<CallApiService> {
  const CallApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'callApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$callApiHash();

  @$internal
  @override
  $ProviderElement<CallApiService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CallApiService create(Ref ref) {
    return callApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CallApiService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CallApiService>(value),
    );
  }
}

String _$callApiHash() => r'54597e5f22ba47abf4d8585071214ad878d86bdf';

@ProviderFor(callTransport)
const callTransportProvider = CallTransportProvider._();

final class CallTransportProvider
    extends $FunctionalProvider<CallTransport, CallTransport, CallTransport>
    with $Provider<CallTransport> {
  const CallTransportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'callTransportProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$callTransportHash();

  @$internal
  @override
  $ProviderElement<CallTransport> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CallTransport create(Ref ref) {
    return callTransport(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CallTransport value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CallTransport>(value),
    );
  }
}

String _$callTransportHash() => r'5f85c0c3c9f32151fbab3672e41125ed0cf7c374';

@ProviderFor(callSystemUi)
const callSystemUiProvider = CallSystemUiProvider._();

final class CallSystemUiProvider
    extends $FunctionalProvider<CallSystemUi, CallSystemUi, CallSystemUi>
    with $Provider<CallSystemUi> {
  const CallSystemUiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'callSystemUiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$callSystemUiHash();

  @$internal
  @override
  $ProviderElement<CallSystemUi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CallSystemUi create(Ref ref) {
    return callSystemUi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CallSystemUi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CallSystemUi>(value),
    );
  }
}

String _$callSystemUiHash() => r'2eb9c8dbecc06f921282304657ca6edd3de2ed24';

@ProviderFor(callPeerFactory)
const callPeerFactoryProvider = CallPeerFactoryProvider._();

final class CallPeerFactoryProvider
    extends
        $FunctionalProvider<CallPeerFactory, CallPeerFactory, CallPeerFactory>
    with $Provider<CallPeerFactory> {
  const CallPeerFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'callPeerFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$callPeerFactoryHash();

  @$internal
  @override
  $ProviderElement<CallPeerFactory> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CallPeerFactory create(Ref ref) {
    return callPeerFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CallPeerFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CallPeerFactory>(value),
    );
  }
}

String _$callPeerFactoryHash() => r'9806e27f4c2369fa7afc91e51d4fe741df0a7634';

@ProviderFor(callTimerFactory)
const callTimerFactoryProvider = CallTimerFactoryProvider._();

final class CallTimerFactoryProvider
    extends
        $FunctionalProvider<
          CallTimerFactory,
          CallTimerFactory,
          CallTimerFactory
        >
    with $Provider<CallTimerFactory> {
  const CallTimerFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'callTimerFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$callTimerFactoryHash();

  @$internal
  @override
  $ProviderElement<CallTimerFactory> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CallTimerFactory create(Ref ref) {
    return callTimerFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CallTimerFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CallTimerFactory>(value),
    );
  }
}

String _$callTimerFactoryHash() => r'ebbde41018d85e3c725e9e6cf5a0066695936f41';

/// The driver's one call at a time, from ring to hang-up: places calls,
/// takes incoming ones from the socket, pushes and the system call UI, runs
/// the WebRTC [CallSession] once answered, and ends it on `call_ended`, a
/// rejected signal or a link that won't come back.

@ProviderFor(CallController)
const callControllerProvider = CallControllerProvider._();

/// The driver's one call at a time, from ring to hang-up: places calls,
/// takes incoming ones from the socket, pushes and the system call UI, runs
/// the WebRTC [CallSession] once answered, and ends it on `call_ended`, a
/// rejected signal or a link that won't come back.
final class CallControllerProvider
    extends $NotifierProvider<CallController, CallState> {
  /// The driver's one call at a time, from ring to hang-up: places calls,
  /// takes incoming ones from the socket, pushes and the system call UI, runs
  /// the WebRTC [CallSession] once answered, and ends it on `call_ended`, a
  /// rejected signal or a link that won't come back.
  const CallControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'callControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$callControllerHash();

  @$internal
  @override
  CallController create() => CallController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CallState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CallState>(value),
    );
  }
}

String _$callControllerHash() => r'382cca050d38ed5fffa7143316335c2d8bb605b7';

/// The driver's one call at a time, from ring to hang-up: places calls,
/// takes incoming ones from the socket, pushes and the system call UI, runs
/// the WebRTC [CallSession] once answered, and ends it on `call_ended`, a
/// rejected signal or a link that won't come back.

abstract class _$CallController extends $Notifier<CallState> {
  CallState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<CallState, CallState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CallState, CallState>,
              CallState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
