import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:massdrive/core/models/socket_message_model.dart';
import 'package:massdrive/core/services/socket_service.dart';
import 'package:massdrive/features/chat/domain/entities/chat_message.dart';
import 'package:massdrive/features/chat/domain/entities/chat_vertical.dart';
import 'package:massdrive/features/chat/domain/repositories/chat_repository.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_controller.g.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
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
  late final String _jobId;
  late final ChatVertical _vertical;
  late final ChatRepository _chatRepository;

  String get _roomId => _vertical.roomId(_jobId);

  @override
  ChatState build(String jobId, ChatVertical vertical) {
    _jobId = jobId;
    _vertical = vertical;
    _chatRepository = getIt<ChatRepository>();

    final socket = ref.watch(socketServiceProvider);
    _socketSub?.cancel();
    _socketSub = socket.messages.listen(_onSocketMessage);

    ref.onDispose(() => _socketSub?.cancel());

    Future.microtask(fetchHistory);
    return const ChatState(isLoading: true);
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
        state = state.copyWith(messages: [...state.messages, newMessage]);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('ChatController: parse chat_message error: $e');
    }
  }

  Future<void> fetchHistory({int? limit, String? before, bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true, error: null);
    try {
      final history = await _chatRepository.getChatHistory(
        _jobId,
        _vertical,
        limit: limit,
        before: before,
      );
      state = state.copyWith(messages: history, isLoading: false);
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

  Future<void> sendImage(File file) async {
    state = state.copyWith(isSending: true);
    try {
      final fileKey = await _chatRepository.uploadChatImage(
        id: _jobId,
        vertical: _vertical,
        file: file,
      );
      final ok = await _chatRepository.sendMessageRest(
        id: _jobId,
        vertical: _vertical,
        msgType: 'image',
        text: '',
        fileKey: fileKey,
      );
      if (ok) {
        await fetchHistory(silent: true);
      } else {
        state = state.copyWith(error: 'ส่งรูปภาพไม่สำเร็จ');
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isSending: false);
    }
  }
}
