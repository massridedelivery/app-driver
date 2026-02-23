// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shake_detector_manager.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(shakeDetectorManager)
const shakeDetectorManagerProvider = ShakeDetectorManagerProvider._();

final class ShakeDetectorManagerProvider
    extends
        $FunctionalProvider<
          ShakeDetectorManager,
          ShakeDetectorManager,
          ShakeDetectorManager
        >
    with $Provider<ShakeDetectorManager> {
  const ShakeDetectorManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shakeDetectorManagerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shakeDetectorManagerHash();

  @$internal
  @override
  $ProviderElement<ShakeDetectorManager> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShakeDetectorManager create(Ref ref) {
    return shakeDetectorManager(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShakeDetectorManager value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShakeDetectorManager>(value),
    );
  }
}

String _$shakeDetectorManagerHash() =>
    r'7f3ba40b743ba2fa87579d3b52dd730e076372fc';

@ProviderFor(shakeEvents)
const shakeEventsProvider = ShakeEventsProvider._();

final class ShakeEventsProvider
    extends $FunctionalProvider<AsyncValue<void>, void, Stream<void>>
    with $FutureModifier<void>, $StreamProvider<void> {
  const ShakeEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shakeEventsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shakeEventsHash();

  @$internal
  @override
  $StreamProviderElement<void> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<void> create(Ref ref) {
    return shakeEvents(ref);
  }
}

String _$shakeEventsHash() => r'15da193e798c74878c4e6109cba8a7de49f12545';
