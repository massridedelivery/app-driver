import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/features/chat/data/sources/chat_api_service.dart';
import 'package:massdrive/features/chat/domain/entities/chat_message.dart';
import 'package:massdrive/features/chat/domain/repositories/chat_repository.dart';

@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  final ChatApiService _chatApiService;

  ChatRepositoryImpl(this._chatApiService);

  @override
  Future<List<ChatMessage>> getChatHistory(
    String jobId, {
    int? limit,
    String? before,
  }) async {
    try {
      final response = await _chatApiService.getChatHistory(
        jobId,
        limit: limit,
        before: before,
      );
      final list = response.data;
      if (list == null) return [];
      return list.map((item) => ChatMessage.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('ChatRepository: getChatHistory error: $e');
      return [];
    }
  }

  @override
  Future<bool> sendMessageRest({
    required String jobId,
    required String roomId,
    required String msgType,
    required String text,
  }) async {
    try {
      final response = await _chatApiService.sendMessageRest(
        jobId: jobId,
        roomId: roomId,
        msgType: msgType,
        text: text,
      );
      final data = response.data;
      return data?['message'] == 'sent' || response.statusCode == 201;
    } catch (e) {
      debugPrint('ChatRepository: sendMessageRest error: $e');
      return false;
    }
  }

  @override
  Future<String> uploadChatImage({required String jobId, required File file}) async {
    try {
      final ext = file.path.split('.').last.toLowerCase();
      String contentType = 'image/jpeg';
      if (ext == 'png') contentType = 'image/png';
      if (ext == 'webp') contentType = 'image/webp';

      // Step 1: GET pre-signed URL
      final presignedResponse = await _chatApiService.getPresignedUploadUrl(
        contentType: contentType,
        jobId: jobId,
      );
      final data = presignedResponse.data;
      if (data == null) throw Exception('Failed to get presigned upload URL');

      final String uploadUrl = data['upload_url'] as String;
      final String fileKey = data['file_key'] as String;

      // Step 2: PUT file to S3
      final fileBytes = await file.readAsBytes();
      await _chatApiService.uploadFileToPresignedUrl(
        uploadUrl: uploadUrl,
        fileBytes: fileBytes,
        contentType: contentType,
      );

      // Step 3: POST media/confirm
      final confirmResponse = await _chatApiService.confirmMediaUpload(fileKey);
      final confirmData = confirmResponse.data;
      final bool confirmed = confirmData?['confirmed'] as bool? ?? false;
      if (!confirmed) {
        throw Exception('Media confirmation failed for file_key: $fileKey');
      }

      // Step 4: GET pre-signed view URL
      final viewResponse = await _chatApiService.getMediaViewUrl(fileKey);
      final viewData = viewResponse.data;
      final String viewUrl = viewData?['view_url'] as String? ?? '';
      if (viewUrl.isEmpty) {
        throw Exception('Failed to get media view URL');
      }

      return viewUrl;
    } catch (e) {
      debugPrint('ChatRepository: uploadChatImage error: $e');
      rethrow;
    }
  }
}
