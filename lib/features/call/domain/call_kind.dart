import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/features/chat/domain/entities/chat_vertical.dart';

/// Which kind of order a call belongs to (`kind` on every call view, frame and
/// push). Only the endpoint that starts the call differs between them.
enum CallKind {
  ride,
  food,
  messenger;

  /// `ride` | `food` | `messenger`; null for anything else.
  static CallKind? fromApi(Object? value) {
    final name = value?.toString().toLowerCase();
    for (final k in CallKind.values) {
      if (k.name == name) return k;
    }
    return null;
  }

  /// Driver-side endpoint that places a call to the order's customer.
  String startPath(String jobId) => switch (this) {
    CallKind.ride => Endpoints.rideCallStart,
    CallKind.food => Endpoints.foodCallStart,
    CallKind.messenger => Endpoints.messengerCallStart,
  }.replaceAll(':id', jobId);

  /// The order's chat (missed / declined calls suggest it).
  ChatVertical get chatVertical => switch (this) {
    CallKind.ride => ChatVertical.ride,
    CallKind.food => ChatVertical.food,
    CallKind.messenger => ChatVertical.messenger,
  };

  static CallKind fromChatVertical(ChatVertical vertical) => switch (vertical) {
    ChatVertical.ride => CallKind.ride,
    ChatVertical.food => CallKind.food,
    ChatVertical.messenger => CallKind.messenger,
  };
}
