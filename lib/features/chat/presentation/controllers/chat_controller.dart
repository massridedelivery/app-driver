import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_key.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_manager.dart';
import 'package:massdrive/features/chat/domain/entities/chat_message.dart';
import 'package:massdrive/features/chat/domain/repositories/chat_repository.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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

@riverpod
class ChatController extends _$ChatController {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  late final String _jobId;
  late final ChatRepository _chatRepository;

  @override
  ChatState build(String jobId) {
    _jobId = jobId;
    _chatRepository = getIt<ChatRepository>();

    ref.onDispose(() {
      _subscription?.cancel();
      _channel?.sink.close();
    });

    // Start fetching and connecting
    Future.microtask(() => init());

    return const ChatState(isLoading: true);
  }

  Future<void> init() async {
    await fetchHistory();
    await connectWebSocket();
  }

  Future<void> fetchHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final history = await _chatRepository.getChatHistory(_jobId);
      state = state.copyWith(messages: history, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> connectWebSocket() async {
    if (_isConnected) return;
    try {
      final secureStorage = SecureStorageManager();
      final token = await secureStorage.read(SecureStorageKey.accessToken);
      if (token == null || token.isEmpty) return;

      final wsUrl = 'wss://driver-api-dev.nutchaphut.dev/ws/chat?job_id=$_jobId&token=${token.trim()}';
      if (kDebugMode) debugPrint('ChatController: Connecting to chat WS: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      await _channel!.ready;

      _isConnected = true;
      if (kDebugMode) debugPrint('ChatController: Chat WebSocket connected successfully.');

      _subscription = _channel!.stream.listen(
        (data) {
          if (kDebugMode) debugPrint('ChatController WS Received: $data');
          try {
            final jsonMap = jsonDecode(data.toString());
            final type = jsonMap['type'];
            if (type == 'chat_message') {
              final messageData = jsonMap['data'] ?? jsonMap;
              final newMessage = ChatMessage.fromJson(messageData as Map<String, dynamic>);

              // Append to list if not already present to avoid duplicates
              if (!state.messages.any((m) => m.id == newMessage.id)) {
                state = state.copyWith(
                  messages: [...state.messages, newMessage],
                );
              }
            }
          } catch (e) {
            if (kDebugMode) debugPrint('ChatController WS Parse error: $e');
          }
        },
        onError: (err) {
          if (kDebugMode) debugPrint('ChatController WS Error: $err');
          _isConnected = false;
        },
        onDone: () {
          if (kDebugMode) debugPrint('ChatController WS Closed');
          _isConnected = false;
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('ChatController WS Connection error: $e');
      _isConnected = false;
    }
  }

  void sendMessage(String text) {
    if (!_isConnected || _channel == null) {
      if (kDebugMode) debugPrint('ChatController: Cannot send message, WS not connected. Trying to reconnect...');
      connectWebSocket().then((_) {
        if (_isConnected && _channel != null) {
          _sendPayload(text);
        }
      });
      return;
    }
    _sendPayload(text);
  }

  void _sendPayload(String text) {
    final payload = {
      'type': 'chat_message',
      'room_id': 'job:$_jobId',
      'content': text,
      'msg_type': 'text',
    };

    final jsonStr = jsonEncode(payload);
    _channel!.sink.add(jsonStr);
    if (kDebugMode) debugPrint('ChatController Sent: $jsonStr');
  }

  Future<void> sendImage(File file) async {
    state = state.copyWith(isSending: true);
    try {
      // 1. Upload image and get view url
      final viewUrl = await _chatRepository.uploadChatImage(
        jobId: _jobId,
        file: file,
      );

      // 2. Send image message over WebSocket
      if (!_isConnected || _channel == null) {
        await connectWebSocket();
      }

      if (_isConnected && _channel != null) {
        final payload = {
          'type': 'chat_message',
          'room_id': 'job:$_jobId',
          'content': '[รูปภาพ]',
          'msg_type': 'image',
          'media_url': viewUrl,
        };

        final jsonStr = jsonEncode(payload);
        _channel!.sink.add(jsonStr);
        if (kDebugMode) debugPrint('ChatController Sent Image Msg: $jsonStr');
      } else {
        throw Exception('WebSocket not connected. Cannot send image message.');
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isSending: false);
    }
  }
}
