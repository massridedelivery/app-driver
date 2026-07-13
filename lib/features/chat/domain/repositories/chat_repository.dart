import 'dart:io';
import 'package:massdrive/features/chat/domain/entities/chat_message.dart';
import 'package:massdrive/features/chat/domain/entities/chat_vertical.dart';

abstract class ChatRepository {
  /// Fetches the historical chat messages for an order/job in a vertical.
  Future<List<ChatMessage>> getChatHistory(
    String id,
    ChatVertical vertical, {
    int? limit,
    String? before,
  });

  /// Uploads an image file to S3/MinIO for chat and returns its `file_key`
  /// (to be sent with an `image` message; the backend resolves it to a URL).
  Future<String> uploadChatImage({
    required String id,
    required ChatVertical vertical,
    required File file,
  });

  /// Sends a chat message to the room via REST.
  Future<bool> sendMessageRest({
    required String id,
    required ChatVertical vertical,
    required String msgType,
    required String text,
    String? fileKey,
  });
}
