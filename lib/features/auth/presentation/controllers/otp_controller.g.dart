// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OtpController)
const otpControllerProvider = OtpControllerProvider._();

final class OtpControllerProvider
    extends $NotifierProvider<OtpController, OtpState> {
  const OtpControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'otpControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$otpControllerHash();

  @$internal
  @override
  OtpController create() => OtpController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OtpState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OtpState>(value),
    );
  }
}

String _$otpControllerHash() => r'9bfd354402d881f98db91982a20288265f6d0043';

abstract class _$OtpController extends $Notifier<OtpState> {
  OtpState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<OtpState, OtpState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OtpState, OtpState>,
              OtpState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
