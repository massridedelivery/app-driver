import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/features/chat/domain/entities/chat_vertical.dart';

abstract class ChatApiService {
  /// Fetches historical chat messages for an order/job in a given vertical.
  Future<Response<List<dynamic>>> getChatHistory(
    String id,
    ChatVertical vertical, {
    int? limit,
    String? before,
  });

  /// Sends a chat message to the room via REST.
  Future<Response<Map<String, dynamic>>> sendMessageRest({
    required String id,
    required ChatVertical vertical,
    required String msgType,
    required String text,
    String? fileKey,
  });

  /// Requests a pre-signed S3/MinIO upload URL for chat media.
  Future<Response<Map<String, dynamic>>> getPresignedUploadUrl({
    required String contentType,
    required String id,
    required ChatVertical vertical,
  });

  /// Uploads binary file bytes directly to the pre-signed URL.
  Future<void> uploadFileToPresignedUrl({
    required String uploadUrl,
    required List<int> fileBytes,
    required String contentType,
  });

  /// Confirms media upload with the backend after S3 upload succeeds.
  Future<Response<Map<String, dynamic>>> confirmMediaUpload(String fileKey);

  /// Gets temporary view URL for the uploaded media.
  Future<Response<Map<String, dynamic>>> getMediaViewUrl(String fileKey);
}

@LazySingleton(as: ChatApiService)
class ChatApiServiceImpl implements ChatApiService {
  final Dio _dio;

  ChatApiServiceImpl(this._dio);

  @override
  Future<Response<List<dynamic>>> getChatHistory(
    String id,
    ChatVertical vertical, {
    int? limit,
    String? before,
  }) async {
    final queryParams = <String, dynamic>{};
    if (limit != null) queryParams['limit'] = limit;
    if (before != null) queryParams['before'] = before;

    return await _dio.get<List<dynamic>>(
      vertical.chatPath(id),
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  @override
  Future<Response<Map<String, dynamic>>> sendMessageRest({
    required String id,
    required ChatVertical vertical,
    required String msgType,
    required String text,
    String? fileKey,
  }) async {
    return await _dio.post<Map<String, dynamic>>(
      vertical.chatPath(id),
      data: {
        'room_id': vertical.roomId(id),
        'msg_type': msgType,
        'text': text,
        if (fileKey != null) 'file_key': fileKey,
      },
    );
  }

  @override
  Future<Response<Map<String, dynamic>>> getPresignedUploadUrl({
    required String contentType,
    required String id,
    required ChatVertical vertical,
  }) async {
    final queryParams = <String, dynamic>{
      'category': 'chat',
      'content_type': contentType,
      'room_id': vertical.roomId(id),
    };

    return await _dio.get<Map<String, dynamic>>(
      Endpoints.documentUploadUrl,
      queryParameters: queryParams,
    );
  }

  @override
  Future<void> uploadFileToPresignedUrl({
    required String uploadUrl,
    required List<int> fileBytes,
    required String contentType,
  }) async {
    final storageDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 120),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    await storageDio.put(
      uploadUrl,
      data: fileBytes,
      options: Options(
        contentType: contentType,
        headers: {
          'Content-Length': fileBytes.length,
        },
      ),
    );
  }

  @override
  Future<Response<Map<String, dynamic>>> confirmMediaUpload(String fileKey) async {
    return await _dio.post<Map<String, dynamic>>(
      Endpoints.mediaConfirm,
      data: {'file_key': fileKey},
    );
  }

  @override
  Future<Response<Map<String, dynamic>>> getMediaViewUrl(String fileKey) async {
    return await _dio.get<Map<String, dynamic>>(
      Endpoints.mediaView,
      queryParameters: {'key': fileKey},
    );
  }
}
