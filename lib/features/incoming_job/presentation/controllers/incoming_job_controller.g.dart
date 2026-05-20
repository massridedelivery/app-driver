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
        isAutoDispose: false,
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
    r'8f28d545155ca6d3feb8e82a2bdfe912145ccd50';

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
