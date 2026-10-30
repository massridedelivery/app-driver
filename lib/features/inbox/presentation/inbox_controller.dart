import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/core/auth/session_notifier.dart';
import 'package:massdrive/features/inbox/data/inbox_api.dart';
import 'package:massdrive/features/inbox/domain/campaign_push.dart';
import 'package:massdrive/features/inbox/domain/inbox_message.dart';

@immutable
class InboxState {
  const InboxState({
    this.items = const [],
    this.unreadCount = 0,
    this.loaded = false,
    this.loading = false,
    this.loadingMore = false,
    this.hasMore = false,
    this.failed = false,
  });

  final List<InboxMessage> items;

  /// The whole inbox's unread count, from the backend: drives the badge.
  final int unreadCount;

  /// The first page has arrived at least once.
  final bool loaded;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;

  /// The last full load failed (and nothing is loaded to show instead).
  final bool failed;

  bool get isEmpty => loaded && items.isEmpty;

  InboxState copyWith({
    List<InboxMessage>? items,
    int? unreadCount,
    bool? loaded,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    bool? failed,
  }) => InboxState(
    items: items ?? this.items,
    unreadCount: unreadCount ?? this.unreadCount,
    loaded: loaded ?? this.loaded,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    hasMore: hasMore ?? this.hasMore,
    failed: failed ?? this.failed,
  );
}

/// The driver's inbox and its unread badge. Kept alive for the session so the
/// bell on the home map and the inbox screen share one count.
class InboxController extends Notifier<InboxState> {
  static const pageSize = 20;

  InboxApi get _api => ref.read(inboxApiProvider);

  @override
  InboxState build() {
    // Another driver may sign in next: drop this one's messages on logout.
    void onSession() {
      if (!SessionNotifier.instance.isAuthenticated) {
        state = const InboxState();
      }
    }

    // A campaign push arrived: re-read the badge.
    void onNewMessage() => refreshUnread();

    SessionNotifier.instance.addListener(onSession);
    InboxUpdates.instance.addListener(onNewMessage);
    ref.onDispose(() {
      SessionNotifier.instance.removeListener(onSession);
      InboxUpdates.instance.removeListener(onNewMessage);
    });
    return const InboxState();
  }

  /// First page, replacing whatever is loaded.
  Future<void> refresh() async {
    state = state.copyWith(loading: true, failed: false);
    try {
      final page = await _api.list(limit: pageSize);
      state = state.copyWith(
        items: page.items,
        unreadCount: page.unreadCount,
        loaded: true,
        loading: false,
        hasMore: page.items.length == pageSize,
      );
    } catch (e) {
      debugPrint('Inbox: load failed: $e');
      state = state.copyWith(loading: false, failed: !state.loaded);
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore || state.loading) return;
    state = state.copyWith(loadingMore: true);
    try {
      final page = await _api.list(limit: pageSize, offset: state.items.length);
      final known = {for (final m in state.items) m.id};
      state = state.copyWith(
        items: [
          ...state.items,
          ...page.items.where((m) => !known.contains(m.id)),
        ],
        unreadCount: page.unreadCount,
        loadingMore: false,
        hasMore: page.items.length == pageSize,
      );
    } catch (e) {
      debugPrint('Inbox: load more failed: $e');
      state = state.copyWith(loadingMore: false);
    }
  }

  /// Just the badge: one row is enough to read `unread_count`. Failures keep
  /// the last count.
  Future<void> refreshUnread() async {
    try {
      final page = await _api.list(limit: 1);
      state = state.copyWith(unreadCount: page.unreadCount);
    } catch (e) {
      debugPrint('Inbox: unread count failed: $e');
    }
  }

  /// Opened a message. Shown as read at once; a failed call is retried the
  /// next time it's opened.
  Future<void> markRead(InboxMessage message) async {
    if (message.isRead) return;
    _replace(message.id, (m) => m.markedRead(DateTime.now()));
    state = state.copyWith(
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
    );
    try {
      await _api.markRead(message.id);
    } catch (e) {
      debugPrint('Inbox: mark read failed: $e');
    }
  }

  /// A tapped campaign push whose row isn't among the loaded ones.
  Future<void> markReadById(String id) async {
    try {
      await _api.markRead(id);
    } catch (e) {
      debugPrint('Inbox: mark read failed: $e');
    }
    await refreshUnread();
  }

  /// Swipe to delete: the row goes at once and comes back if the backend
  /// refuses. False when it came back.
  Future<bool> delete(InboxMessage message) async {
    final index = state.items.indexWhere((m) => m.id == message.id);
    if (index < 0) return true;
    final before = state;
    state = state.copyWith(
      items: [...state.items]..removeAt(index),
      unreadCount: !message.isRead && state.unreadCount > 0
          ? state.unreadCount - 1
          : state.unreadCount,
    );
    try {
      await _api.delete(message.id);
    } catch (e) {
      debugPrint('Inbox: delete failed: $e');
      final items = [...state.items]
        ..insert(index.clamp(0, state.items.length), message);
      state = state.copyWith(items: items, unreadCount: before.unreadCount);
      return false;
    }
    await refreshUnread();
    return true;
  }

  /// "ลบทั้งหมด" (after the driver confirmed). False if it failed; the list
  /// is left as it was.
  Future<bool> deleteAll() async {
    try {
      await _api.deleteAll();
    } catch (e) {
      debugPrint('Inbox: delete all failed: $e');
      return false;
    }
    state = state.copyWith(items: const [], hasMore: false, unreadCount: 0);
    await refreshUnread();
    return true;
  }

  /// "อ่านทั้งหมด". False if it failed.
  Future<bool> readAll() async {
    try {
      await _api.readAll();
    } catch (e) {
      debugPrint('Inbox: read all failed: $e');
      return false;
    }
    final now = DateTime.now();
    state = state.copyWith(
      items: [for (final m in state.items) m.markedRead(now)],
      unreadCount: 0,
    );
    return true;
  }

  void _replace(String id, InboxMessage Function(InboxMessage) change) {
    state = state.copyWith(
      items: [for (final m in state.items) m.id == id ? change(m) : m],
    );
  }
}

final inboxControllerProvider = NotifierProvider<InboxController, InboxState>(
  InboxController.new,
);
