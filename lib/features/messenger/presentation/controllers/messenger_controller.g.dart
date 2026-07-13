// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messenger_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the messenger offer + active-delivery lifecycle (SCRUM-41 §6/§7).

@ProviderFor(MessengerController)
const messengerControllerProvider = MessengerControllerProvider._();

/// Drives the messenger offer + active-delivery lifecycle (SCRUM-41 §6/§7).
final class MessengerControllerProvider
    extends $NotifierProvider<MessengerController, MessengerState> {
  /// Drives the messenger offer + active-delivery lifecycle (SCRUM-41 §6/§7).
  const MessengerControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messengerControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messengerControllerHash();

  @$internal
  @override
  MessengerController create() => MessengerController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessengerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessengerState>(value),
    );
  }
}

String _$messengerControllerHash() =>
    r'18b52aab167ce5a4ab625e91020779f95eb900db';

/// Drives the messenger offer + active-delivery lifecycle (SCRUM-41 §6/§7).

abstract class _$MessengerController extends $Notifier<MessengerState> {
  MessengerState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<MessengerState, MessengerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MessengerState, MessengerState>,
              MessengerState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
