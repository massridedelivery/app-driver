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
    extends $AsyncNotifierProvider<AppStartupController, StartupResult> {
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
    r'd5fe7e158412a12526e8e8d04f08ba521dba0000';

abstract class _$AppStartupController extends $AsyncNotifier<StartupResult> {
  FutureOr<StartupResult> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<StartupResult>, StartupResult>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<StartupResult>, StartupResult>,
              AsyncValue<StartupResult>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
