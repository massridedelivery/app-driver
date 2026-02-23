// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'developer_options_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DeveloperOptionsController)
const developerOptionsControllerProvider =
    DeveloperOptionsControllerProvider._();

final class DeveloperOptionsControllerProvider
    extends
        $NotifierProvider<DeveloperOptionsController, DeveloperOptionsState> {
  const DeveloperOptionsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'developerOptionsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$developerOptionsControllerHash();

  @$internal
  @override
  DeveloperOptionsController create() => DeveloperOptionsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeveloperOptionsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeveloperOptionsState>(value),
    );
  }
}

String _$developerOptionsControllerHash() =>
    r'24e1374b3aed9457f236a4d728dc1f21938985a6';

abstract class _$DeveloperOptionsController
    extends $Notifier<DeveloperOptionsState> {
  DeveloperOptionsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<DeveloperOptionsState, DeveloperOptionsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DeveloperOptionsState, DeveloperOptionsState>,
              DeveloperOptionsState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
