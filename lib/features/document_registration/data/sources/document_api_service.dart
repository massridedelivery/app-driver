import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';

abstract class DocumentApiService {
  Future<Response<Map<String, dynamic>>> confirmDocument(
    Map<String, dynamic> data,
  );
}

@LazySingleton(as: DocumentApiService)
class DocumentApiServiceImpl implements DocumentApiService {
  final Dio _dio;

  DocumentApiServiceImpl(this._dio);

  @override
  Future<Response<Map<String, dynamic>>> confirmDocument(
    Map<String, dynamic> data,
  ) async {
    return await _dio.post<Map<String, dynamic>>(
      Endpoints.documentConfirm,
      data: data,
    );
  }
}
