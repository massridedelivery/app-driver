import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/features/chat/data/sources/chat_api_service.dart';
import 'package:massdrive/features/chat/domain/entities/chat_message.dart';
import 'package:massdrive/features/chat/domain/entities/chat_vertical.dart';
import 'package:massdrive/features/chat/domain/repositories/chat_repository.dart';

@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  final ChatApiService _chatApiService;

  ChatRepositoryImpl(this._chatApiService);

  @override
  Future<List<ChatMessage>> getChatHistory(
    String id,
    ChatVertical vertical, {
    int? limit,
    String? before,
  }) async {
    try {
      final response = await _chatApiService.getChatHistory(
        id,
        vertical,
        limit: limit,
        before: before,
      );
      final list = response.data;
      if (list == null) return [];
      return list
          .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ChatRepository: getChatHistory error: $e');
      return [];
    }
  }

  @override
  Future<bool> sendMessageRest({
    required String id,
    required ChatVertical vertical,
    required String msgType,
    required String text,
    String? fileKey,
  }) async {
    try {
      final response = await _chatApiService.sendMessageRest(
        id: id,
        vertical: vertical,
        msgType: msgType,
        text: text,
        fileKey: fileKey,
      );
      final data = response.data;
      return data?['message'] == 'sent' || response.statusCode == 201;
    } catch (e) {
      debugPrint('ChatRepository: sendMessageRest error: $e');
      return false;
    }
  }

  @override
  Future<bool> reportChat(
    String id,
    ChatVertical vertical,
    String reason,
  ) async {
    try {
      final response = await _chatApiService.reportChat(
        roomId: vertical.roomId(id),
        reason: reason,
      );
      final code = response.statusCode ?? 0;
      return code >= 200 && code < 300;
    } catch (e) {
      debugPrint('ChatRepository: reportChat error: $e');
      return false;
    }
  }

  @override
  Future<bool> setBlock(String id, ChatVertical vertical, bool blocked) async {
    try {
      final response = await _chatApiService.setBlock(
        roomId: vertical.roomId(id),
        blocked: blocked,
      );
      final code = response.statusCode ?? 0;
      return code >= 200 && code < 300;
    } catch (e) {
      debugPrint('ChatRepository: setBlock error: $e');
      return false;
    }
  }
}
