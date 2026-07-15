/// Which vertical a chat room belongs to. Drives the REST path + room-id prefix
/// so one chat module serves ride, food, and messenger (SCRUM-41 chat update).
enum ChatVertical {
  ride,
  food,
  messenger;

  /// Room-id prefix used by the backend (`job:`, `order:`, `messenger:`).
  String get roomPrefix => switch (this) {
        ChatVertical.ride => 'job',
        ChatVertical.food => 'order',
        ChatVertical.messenger => 'messenger',
      };

  String roomId(String id) => '$roomPrefix:$id';

  /// Driver-side chat REST endpoint for this vertical.
  String chatPath(String id) => switch (this) {
        ChatVertical.ride => '/api/driver/jobs/$id/chat',
        ChatVertical.food => '/api/food/driver/orders/$id/chat',
        ChatVertical.messenger => '/api/messenger/driver/orders/$id/chat',
      };
}
