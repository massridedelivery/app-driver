// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HistoryController)
const historyControllerProvider = HistoryControllerProvider._();

final class HistoryControllerProvider
    extends $NotifierProvider<HistoryController, HistoryState> {
  const HistoryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyControllerHash();

  @$internal
  @override
  HistoryController create() => HistoryController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HistoryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HistoryState>(value),
    );
  }
}

String _$historyControllerHash() => r'8a502df84bca908bccbf50417f4c91ee665f34b7';

abstract class _$HistoryController extends $Notifier<HistoryState> {
  HistoryState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<HistoryState, HistoryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HistoryState, HistoryState>,
              HistoryState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
