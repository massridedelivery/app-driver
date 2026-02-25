// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_login_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EmailLoginController)
const emailLoginControllerProvider = EmailLoginControllerProvider._();

final class EmailLoginControllerProvider
    extends $NotifierProvider<EmailLoginController, EmailLoginState> {
  const EmailLoginControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'emailLoginControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$emailLoginControllerHash();

  @$internal
  @override
  EmailLoginController create() => EmailLoginController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EmailLoginState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EmailLoginState>(value),
    );
  }
}

String _$emailLoginControllerHash() =>
    r'51601e73870424c41cf60a70106e8a6ce08364d3';

abstract class _$EmailLoginController extends $Notifier<EmailLoginState> {
  EmailLoginState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<EmailLoginState, EmailLoginState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EmailLoginState, EmailLoginState>,
              EmailLoginState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
