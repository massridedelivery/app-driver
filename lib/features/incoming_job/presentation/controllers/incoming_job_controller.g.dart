// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incoming_job_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(IncomingJobController)
const incomingJobControllerProvider = IncomingJobControllerProvider._();

final class IncomingJobControllerProvider
    extends $NotifierProvider<IncomingJobController, IncomingJobState> {
  const IncomingJobControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'incomingJobControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$incomingJobControllerHash();

  @$internal
  @override
  IncomingJobController create() => IncomingJobController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IncomingJobState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IncomingJobState>(value),
    );
  }
}

String _$incomingJobControllerHash() =>
    r'9728e332bc98911d7bfad26d15b281f411e4ec4e';

abstract class _$IncomingJobController extends $Notifier<IncomingJobState> {
  IncomingJobState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<IncomingJobState, IncomingJobState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<IncomingJobState, IncomingJobState>,
              IncomingJobState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
