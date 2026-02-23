// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HomeController)
const homeControllerProvider = HomeControllerProvider._();

final class HomeControllerProvider
    extends $AsyncNotifierProvider<HomeController, HomeScreenState> {
  const HomeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeControllerHash();

  @$internal
  @override
  HomeController create() => HomeController();
}

String _$homeControllerHash() => r'c2e010cd77f1079aff5aec223869048109b0b976';

abstract class _$HomeController extends $AsyncNotifier<HomeScreenState> {
  FutureOr<HomeScreenState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<HomeScreenState>, HomeScreenState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<HomeScreenState>, HomeScreenState>,
              AsyncValue<HomeScreenState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
