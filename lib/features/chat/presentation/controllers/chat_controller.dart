import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:massdrive/core/models/socket_message_model.dart';
import 'package:massdrive/core/services/socket_service.dart';
import 'package:massdrive/features/chat/data/chat_image_outbox.dart';
import 'package:massdrive/features/chat/domain/entities/chat_message.dart';
import 'package:massdrive/features/chat/domain/entities/chat_vertical.dart';
import 'package:massdrive/features/chat/domain/repositories/chat_repository.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_controller.g.dart';

class ChatState {
  final List<ChatMessage> messages;

  /// Photos this driver is still uploading/sending in this room (shown as
  /// local bubbles after [messages] until the server's copy arrives).
  final List<OutboxItem> pending;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.pending = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    List<OutboxItem>? pending,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      pending: pending ?? this.pending,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Chat over the app's single WS channel (SCRUM-41): receive `chat_message`
/// events from the main SocketService, send via the per-vertical REST endpoint.
/// (The old design opened a second WS that the backend tried to bind to a ride,
/// which failed for messenger/food with "no active ride partner found".)
@riverpod
class ChatController extends _$ChatController {
  StreamSubscription? _socketSub;
  StreamSubscription<void>? _outboxSub;
  ChatImageOutbox get _outbox => ChatImageOutbox.instance;
  late final String _jobId;
  late final ChatVertical _vertical;
  late final ChatRepository _chatRepository;

  String get _roomId => _vertical.roomId(_jobId);

  /// Oldest-first ordering, so the list renders in stable chronological order
  /// no matter what order the history endpoint or the socket delivers them in.
  List<ChatMessage> _chronological(List<ChatMessage> list) {
    final sorted = [...list]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted;
  }

  @override
  ChatState build(String jobId, ChatVertical vertical) {
    _jobId = jobId;
    _vertical = vertical;
    _chatRepository = getIt<ChatRepository>();

    final socket = ref.watch(socketServiceProvider);
    _socketSub?.cancel();
    _socketSub = socket.messages.listen(_onSocketMessage);

    _outboxSub?.cancel();
    _outboxSub = _outbox.changes.listen((_) => _syncPending());

    ref.onDispose(() {
      _socketSub?.cancel();
      _outboxSub?.cancel();
    });

    Future.microtask(fetchHistory);
    return ChatState(isLoading: true, pending: _outbox.itemsFor(_roomId));
  }

  /// Whether the server's copy of a queued photo is already in [messages]
  /// (matched by the id the send returned, or the file_key from the WS echo).
  bool _delivered(OutboxItem item, List<ChatMessage> messages) => messages.any(
    (m) =>
        (item.serverId != null && m.id == item.serverId) ||
        (item.fileKey != null &&
            m.fileKey.isNotEmpty &&
            m.fileKey == item.fileKey),
  );

  /// Re-reads this room's queue: drops photos the chat now shows from the
  /// server, and re-syncs history once a photo is sent so its real bubble
  /// (with media_url) replaces the local one.
  void _syncPending() {
    final items = _outbox.itemsFor(_roomId);
    for (final i in items.where((i) => _delivered(i, state.messages))) {
      _outbox.remove(i.localId);
    }
    final pending = items.where((i) => !_delivered(i, state.messages)).toList();
    final newlySent = pending.any(
      (i) =>
          i.status == OutboxStatus.sent &&
          !state.pending.any(
            (p) => p.localId == i.localId && p.status == OutboxStatus.sent,
          ),
    );
    state = state.copyWith(pending: pending);
    if (newlySent) unawaited(_refreshAfterSend());
  }

  Future<void> _refreshAfterSend() async {
    await fetchHistory(silent: true);
    // History now holds the sent photos; let any local copies go.
    for (final i in _outbox.itemsFor(_roomId)) {
      if (i.status == OutboxStatus.sent) _outbox.remove(i.localId);
    }
  }

  void _onSocketMessage(SocketMessageModel msg) {
    if (msg.type != 'chat_message') return;
    final data = msg.data ?? msg.raw['data'] ?? msg.raw;
    if (data is! Map<String, dynamic>) return;

    // Only accept messages for this room (when the envelope says which room).
    final roomId = (data['room_id'] ?? msg.raw['room_id'])?.toString();
    if (roomId != null && roomId != _roomId) return;

    try {
      final newMessage = ChatMessage.fromJson(data);
      if (!state.messages.any((m) => m.id == newMessage.id)) {
        state = state.copyWith(
          messages: _chronological([...state.messages, newMessage]),
        );
        _syncPending();
      }
    } catch (e) {
      if (kDebugMode)
        debugPrint('ChatController: parse chat_message error: $e');
    }
  }

  Future<void> fetchHistory({
    int? limit,
    String? before,
    bool silent = false,
  }) async {
    if (!silent) state = state.copyWith(isLoading: true, error: null);
    try {
      final history = await _chatRepository.getChatHistory(
        _jobId,
        _vertical,
        limit: limit,
        before: before,
      );
      state = state.copyWith(
        messages: _chronological(history),
        isLoading: false,
      );
      _syncPending();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> sendMessage(String text) async {
    final ok = await _chatRepository.sendMessageRest(
      id: _jobId,
      vertical: _vertical,
      msgType: 'text',
      text: text,
    );
    // The backend echoes the message back over the WS; re-sync as a safety net
    // in case that push is missed. Dedup by id prevents duplicates.
    if (ok) {
      await fetchHistory(silent: true);
    } else {
      state = state.copyWith(error: 'ส่งข้อความไม่สำเร็จ');
    }
  }

  /// Queues an already-processed photo (see `prepareChatImage`) with an
  /// optional caption. It shows at once as a local bubble with progress.
  void sendImage(Uint8List jpeg, {String caption = ''}) {
    _outbox.enqueue(
      id: _jobId,
      vertical: _vertical,
      bytes: jpeg,
      caption: caption,
    );
  }

  void retryImage(String localId) => _outbox.retry(localId);

  void discardImage(String localId) => _outbox.remove(localId);

  /// Signed media URLs last 5 minutes: re-read the history for fresh ones.
  Future<void> refreshMediaUrls() => fetchHistory(silent: true);
}
