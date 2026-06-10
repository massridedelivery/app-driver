// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'registration_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RegistrationController)
const registrationControllerProvider = RegistrationControllerProvider._();

final class RegistrationControllerProvider
    extends $NotifierProvider<RegistrationController, RegistrationState> {
  const RegistrationControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'registrationControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$registrationControllerHash();

  @$internal
  @override
  RegistrationController create() => RegistrationController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RegistrationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RegistrationState>(value),
    );
  }
}

String _$registrationControllerHash() =>
    r'2e07500bca991270dc94da14e62951d3c438d8e7';

abstract class _$RegistrationController extends $Notifier<RegistrationState> {
  RegistrationState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<RegistrationState, RegistrationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RegistrationState, RegistrationState>,
              RegistrationState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
