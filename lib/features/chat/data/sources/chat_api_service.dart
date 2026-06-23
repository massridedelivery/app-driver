import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';

abstract class ChatApiService {
  /// Fetches historical chat messages for a specific job.
  Future<Response<List<dynamic>>> getChatHistory(
    String jobId, {
    int? limit,
    String? before,
  });

  /// Sends a chat message to the room via REST.
  Future<Response<Map<String, dynamic>>> sendMessageRest({
    required String jobId,
    required String roomId,
    required String msgType,
    required String text,
  });

  /// Requests a pre-signed S3/MinIO upload URL for chat media.
  Future<Response<Map<String, dynamic>>> getPresignedUploadUrl({
    required String contentType,
    required String jobId,
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
    String jobId, {
    int? limit,
    String? before,
  }) async {
    final endpoint = '/api/driver/jobs/$jobId/chat';
    final queryParams = <String, dynamic>{};
    if (limit != null) queryParams['limit'] = limit;
    if (before != null) queryParams['before'] = before;

    return await _dio.get<List<dynamic>>(
      endpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  @override
  Future<Response<Map<String, dynamic>>> sendMessageRest({
    required String jobId,
    required String roomId,
    required String msgType,
    required String text,
  }) async {
    final endpoint = '/api/driver/jobs/$jobId/chat';
    return await _dio.post<Map<String, dynamic>>(
      endpoint,
      data: {
        'room_id': roomId,
        'msg_type': msgType,
        'text': text,
      },
    );
  }

  @override
  Future<Response<Map<String, dynamic>>> getPresignedUploadUrl({
    required String contentType,
    required String jobId,
  }) async {
    final queryParams = <String, dynamic>{
      'category': 'chat',
      'content_type': contentType,
      'room_id': 'job:$jobId',
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
