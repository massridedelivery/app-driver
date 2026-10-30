/// Where a message's button takes the driver. The backend lets a driver
/// campaign point at home, the quests screen ("incentives") or an https page.
enum InboxLinkKind { quests, web }

class InboxLink {
  const InboxLink.quests() : kind = InboxLinkKind.quests, url = null;
  const InboxLink.web(String this.url) : kind = InboxLinkKind.web;

  final InboxLinkKind kind;
  final String? url;
}

/// One row of `GET /api/notifications`: a campaign or other in-app message.
class InboxMessage {
  const InboxMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.campaignId,
    this.data = const {},
    this.readAt,
  });

  factory InboxMessage.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return InboxMessage(
      id: json['id']?.toString() ?? '',
      campaignId: json['campaign_id']?.toString(),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      data: rawData is Map
          ? {
              for (final e in rawData.entries)
                if (e.value != null) e.key.toString(): e.value.toString(),
            }
          : const {},
      readAt: DateTime.tryParse(json['read_at']?.toString() ?? '')?.toLocal(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String id;
  final String? campaignId;
  final String title;
  final String body;
  final Map<String, String> data;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;

  InboxMessage markedRead(DateTime at) => InboxMessage(
    id: id,
    campaignId: campaignId,
    title: title,
    body: body,
    data: data,
    readAt: readAt ?? at,
    createdAt: createdAt,
  );

  /// The button on the detail screen, or null for "home" (the driver is a
  /// tap away from it already) and anything this app doesn't route.
  InboxLink? get link {
    final screen = data['screen'];
    final deeplink = data['deeplink'];
    if (screen == 'incentives' || deeplink == '/incentives') {
      return const InboxLink.quests();
    }
    final url = data['url'] ?? deeplink;
    if ((screen == null || screen == 'url') &&
        url != null &&
        url.startsWith('https://')) {
      return InboxLink.web(url);
    }
    return null;
  }
}

/// One page of the inbox. [unreadCount] covers the whole inbox, not the page.
class InboxPage {
  const InboxPage({required this.items, required this.unreadCount});

  factory InboxPage.fromJson(Object? json) {
    final map = json is Map ? json : const {};
    final rawItems = map['items'];
    return InboxPage(
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map((m) => InboxMessage.fromJson(Map<String, dynamic>.from(m)))
                .toList()
          : const [],
      unreadCount: (map['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  final List<InboxMessage> items;
  final int unreadCount;
}
