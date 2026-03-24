import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';

abstract class MediaApiService {
  Future<Response<Map<String, dynamic>>> getUploadUrl(
    Map<String, dynamic> data,
  );
  Future<Response> uploadFileDirectly(
    String uploadUrl,
    List<int> fileBytes,
    String contentType,
  );
}

@LazySingleton(as: MediaApiService)
class MediaApiServiceImpl implements MediaApiService {
  final Dio _dio;
  late final Dio _directUploadDio;

  MediaApiServiceImpl(this._dio) {
    _directUploadDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  @override
  Future<Response<Map<String, dynamic>>> getUploadUrl(
    Map<String, dynamic> data,
  ) async {
    return await _dio.post<Map<String, dynamic>>(
      Endpoints.documentUploadUrl,
      data: data,
    );
  }

  @override
  Future<Response> uploadFileDirectly(
    String uploadUrl,
    List<int> fileBytes,
    String contentType,
  ) async {
    return await _directUploadDio.put(
      uploadUrl,
      data: Stream.fromIterable([fileBytes]),
      options: Options(
        headers: {
          'Content-Type': contentType,
          'Content-Length': fileBytes.length.toString(),
        },
      ),
    );
  }
}
