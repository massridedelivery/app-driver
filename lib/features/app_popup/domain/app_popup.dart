import 'package:flutter/foundation.dart';

/// One launch pop-up from `GET /api/driver/popups/active`.
@immutable
class AppPopup {
  const AppPopup({
    required this.id,
    required this.version,
    required this.imageUrl,
    this.action,
    this.endAt,
  });

  /// Stable for the pop-up's life; a new pop-up has a new id.
  final String id;

  /// Goes up when an admin changes what is shown (or "show it again").
  final int version;
  final String imageUrl;

  /// Null: tapping the image does nothing and there is no button.
  final PopupAction? action;

  /// Informational only — the server filters.
  final DateTime? endAt;

  String get sessionKey => '$id:$version';

  /// Null when the item can't be shown (no id / image).
  static AppPopup? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id']?.toString().trim() ?? '';
    final image = raw['image_url']?.toString().trim() ?? '';
    final version = raw['version'];
    if (id.isEmpty || image.isEmpty || version is! num) return null;
    return AppPopup(
      id: id,
      version: version.toInt(),
      imageUrl: image,
      action: PopupAction.tryParse(raw['action']),
      endAt: DateTime.tryParse(raw['end_at']?.toString() ?? ''),
    );
  }

  /// `{"items":[…], "server_time"}` → the showable items, in order.
  static List<AppPopup> listFrom(Object? body) {
    final items = body is Map ? body['items'] : null;
    if (items is! List) return const [];
    return [
      for (final i in items)
        if (tryParse(i) case final p?) p,
    ];
  }
}

enum PopupActionType { deeplink, url }

@immutable
class PopupAction {
  const PopupAction({required this.type, required this.value, this.buttonText});

  final PopupActionType type;

  /// An in-app path (`/wallet`) for a deeplink, an http(s) link for a url.
  final String value;

  /// When set, a button under the image doing what the image does.
  final String? buttonText;

  static PopupAction? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final type = switch (raw['type']?.toString()) {
      'deeplink' => PopupActionType.deeplink,
      'url' => PopupActionType.url,
      _ => null,
    };
    final value = raw['value']?.toString().trim() ?? '';
    if (type == null || value.isEmpty) return null;
    final text = raw['button_text']?.toString().trim();
    return PopupAction(
      type: type,
      value: value,
      buttonText: text == null || text.isEmpty ? null : text,
    );
  }
}

/// How the card was closed.
@immutable
class PopupOutcome {
  const PopupOutcome({required this.dontShowAgain, this.tapped = false});

  /// "ไม่แสดงหน้านี้ในครั้งถัดไป" was ticked.
  final bool dontShowAgain;

  /// The image or the button was tapped: open the action.
  final bool tapped;
}

/// The device-only dismissal rule: a persistent `{id: version}` map plus
/// the `"<id>:<version>"` keys closed in this process.
class PopupDismissals {
  PopupDismissals(Map<String, int> dismissed) : dismissed = Map.of(dismissed);

  final Map<String, int> dismissed;
  final Set<String> closedThisSession = {};

  bool isSuppressed(AppPopup p) =>
      dismissed[p.id] == p.version || closedThisSession.contains(p.sessionKey);

  /// The first item not suppressed, or null.
  AppPopup? next(List<AppPopup> items) {
    for (final p in items) {
      if (!isSuppressed(p)) return p;
    }
    return null;
  }

  /// Records a close. True when the persistent map changed.
  bool close(AppPopup p, PopupOutcome outcome) {
    closedThisSession.add(p.sessionKey);
    if (!outcome.dontShowAgain) return false;
    dismissed[p.id] = p.version;
    return true;
  }

  /// Drops entries for pop-ups no longer live. True when anything went.
  bool prune(List<AppPopup> live) {
    final ids = {for (final p in live) p.id};
    final before = dismissed.length;
    dismissed.removeWhere((id, _) => !ids.contains(id));
    return dismissed.length != before;
  }
}
