// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChatController)
const chatControllerProvider = ChatControllerFamily._();

final class ChatControllerProvider
    extends $NotifierProvider<ChatController, ChatState> {
  const ChatControllerProvider._({
    required ChatControllerFamily super.from,
    required (String, ChatVertical) super.argument,
  }) : super(
         retry: null,
         name: r'chatControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatControllerHash();

  @override
  String toString() {
    return r'chatControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ChatController create() => ChatController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChatControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatControllerHash() => r'278b5256a70abb313038e27df03380ec31180e86';

final class ChatControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ChatController,
          ChatState,
          ChatState,
          ChatState,
          (String, ChatVertical)
        > {
  const ChatControllerFamily._()
    : super(
        retry: null,
        name: r'chatControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChatControllerProvider call(String jobId, ChatVertical vertical) =>
      ChatControllerProvider._(argument: (jobId, vertical), from: this);

  @override
  String toString() => r'chatControllerProvider';
}

abstract class _$ChatController extends $Notifier<ChatState> {
  late final _$args = ref.$arg as (String, ChatVertical);
  String get jobId => _$args.$1;
  ChatVertical get vertical => _$args.$2;

  ChatState build(String jobId, ChatVertical vertical);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args.$1, _$args.$2);
    final ref = this.ref as $Ref<ChatState, ChatState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChatState, ChatState>,
              ChatState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
