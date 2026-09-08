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

  /// Reports the chat counterpart for [id]/[vertical]. Returns true if the
  /// backend accepted the report (false if it failed or the endpoint isn't up
  /// yet — the UI still acknowledges to the user).
  Future<bool> reportChat(String id, ChatVertical vertical, String reason);

  /// Blocks ([blocked] true) or unblocks (false) the counterpart. Returns true
  /// on success (false if it failed — the app keeps a local block as fallback).
  Future<bool> setBlock(String id, ChatVertical vertical, bool blocked);
}
