import 'package:massdrive/features/chat/domain/entities/chat_vertical.dart';

/// The chat a push opens ("ลูกค้าส่งรูปภาพ" / a new chat message).
class ChatPushTarget {
  const ChatPushTarget(this.vertical, this.id);

  final ChatVertical vertical;

  /// Bare job / order / messenger-order id.
  final String id;

  /// Local-notification payload, so a tap on the foreground copy opens it too.
  String get payload => 'chat|${vertical.name}|$id';

  static ChatPushTarget? fromPayload(String? payload) {
    final parts = payload?.split('|');
    if (parts == null || parts.length != 3 || parts[0] != 'chat') return null;
    final vertical = ChatVertical.values.where((v) => v.name == parts[1]);
    if (vertical.isEmpty || parts[2].isEmpty) return null;
    return ChatPushTarget(vertical.first, parts[2]);
  }

  @override
  bool operator ==(Object other) =>
      other is ChatPushTarget && other.vertical == vertical && other.id == id;

  @override
  int get hashCode => Object.hash(vertical, id);
}

/// Reads a chat push's `room_id` (`job:<id>`, `order:<id>`, `messenger:<id>`,
/// or a bare id with the vertical in `service`/`vertical`). Null when the push
/// isn't a chat message.
ChatPushTarget? chatTargetFromPush(Map<String, dynamic> data) {
  final type = data['type']?.toString().toLowerCase() ?? '';
  final room = data['room_id']?.toString().trim() ?? '';
  if (room.isEmpty || !(type.contains('chat') || data['msg_type'] != null)) {
    return null;
  }
  final colon = room.indexOf(':');
  if (colon > 0) {
    final prefix = room.substring(0, colon);
    final id = room.substring(colon + 1);
    for (final v in ChatVertical.values) {
      if (v.roomPrefix == prefix && id.isNotEmpty) return ChatPushTarget(v, id);
    }
    return null;
  }
  final service =
      (data['service'] ?? data['vertical'])?.toString().toLowerCase() ?? '';
  final vertical = switch (service) {
    'food' => ChatVertical.food,
    'messenger' => ChatVertical.messenger,
    _ => ChatVertical.ride,
  };
  return ChatPushTarget(vertical, room);
}
