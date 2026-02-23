// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OnboardingController)
const onboardingControllerProvider = OnboardingControllerProvider._();

final class OnboardingControllerProvider
    extends $AsyncNotifierProvider<OnboardingController, OnboardingState> {
  const OnboardingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingControllerHash();

  @$internal
  @override
  OnboardingController create() => OnboardingController();
}

String _$onboardingControllerHash() =>
    r'55aca1a4d975deb3b83b1fa897e31d5ecc9fd15f';

abstract class _$OnboardingController extends $AsyncNotifier<OnboardingState> {
  FutureOr<OnboardingState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<OnboardingState>, OnboardingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<OnboardingState>, OnboardingState>,
              AsyncValue<OnboardingState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
