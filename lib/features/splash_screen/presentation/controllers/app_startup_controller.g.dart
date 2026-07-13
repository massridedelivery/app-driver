// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_startup_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppStartupController)
const appStartupControllerProvider = AppStartupControllerProvider._();

final class AppStartupControllerProvider
    extends $AsyncNotifierProvider<AppStartupController, StartupDestination> {
  const AppStartupControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appStartupControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appStartupControllerHash();

  @$internal
  @override
  AppStartupController create() => AppStartupController();
}

String _$appStartupControllerHash() =>
    r'c8661edd69c55067c024a32fae088d24ce95ec00';

abstract class _$AppStartupController
    extends $AsyncNotifier<StartupDestination> {
  FutureOr<StartupDestination> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<StartupDestination>, StartupDestination>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<StartupDestination>, StartupDestination>,
              AsyncValue<StartupDestination>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
