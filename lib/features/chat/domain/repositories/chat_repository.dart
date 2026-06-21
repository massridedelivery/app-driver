import 'dart:io';
import 'package:massdrive/features/chat/domain/entities/chat_message.dart';

abstract class ChatRepository {
  /// Fetches the historical chat messages for the specified job.
  Future<List<ChatMessage>> getChatHistory(String jobId);

  /// Uploads an image file to S3/MinIO for chat and returns the file view URL.
  Future<String> uploadChatImage({required String jobId, required File file});
}
