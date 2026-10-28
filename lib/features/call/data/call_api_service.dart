import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/features/call/domain/call_error.dart';
import 'package:massdrive/features/call/domain/call_kind.dart';
import 'package:massdrive/features/call/domain/call_models.dart';

/// In-app calling REST. Every failure comes out as a [CallError] carrying the
/// HTTP status and the backend's `code`, which decide what the app shows.
abstract class CallApiService {
  Future<CallSettings> getSettings();

  /// Rings the order's customer. 201 → the call view with `ice_servers`.
  Future<CallView> startCall(CallKind kind, String jobId);
  Future<CallView> getCall(String callId);

  /// Answers a ringing call; the view carries `ice_servers`.
  Future<CallView> accept(String callId);
  Future<void> decline(String callId);

  /// Hang up / cancel. [reason] is `failed` when the audio never connected.
  Future<void> end(String callId, {String? reason});
  Future<void> registerVoipToken(String token, {required bool sandbox});
  Future<void> deleteVoipToken(String token, {required bool sandbox});
}

@LazySingleton(as: CallApiService)
class CallApiServiceImpl implements CallApiService {
  CallApiServiceImpl(this._dio);

  final Dio _dio;

  String _path(String template, String callId) =>
      template.replaceAll(':id', callId);

  @override
  Future<CallSettings> getSettings() async => CallSettings.fromJson(
    _body(await _guard(() => _dio.get(Endpoints.callSettings))),
  );

  @override
  Future<CallView> startCall(CallKind kind, String jobId) async =>
      _view(await _guard(() => _dio.post(kind.startPath(jobId))));

  @override
  Future<CallView> getCall(String callId) async =>
      _view(await _guard(() => _dio.get(_path(Endpoints.call, callId))));

  @override
  Future<CallView> accept(String callId) async =>
      _view(await _guard(() => _dio.post(_path(Endpoints.callAccept, callId))));

  @override
  Future<void> decline(String callId) =>
      _guard(() => _dio.post(_path(Endpoints.callDecline, callId)));

  @override
  Future<void> end(String callId, {String? reason}) => _guard(
    () => _dio.post(
      _path(Endpoints.callEnd, callId),
      data: reason == null ? null : {'reason': reason},
    ),
  );

  @override
  Future<void> registerVoipToken(String token, {required bool sandbox}) =>
      _guard(
        () => _dio.post(
          Endpoints.callVoipToken,
          data: {'token': token, 'sandbox': sandbox},
        ),
      );

  @override
  Future<void> deleteVoipToken(String token, {required bool sandbox}) => _guard(
    () => _dio.delete(
      Endpoints.callVoipToken,
      data: {'token': token, 'sandbox': sandbox},
    ),
  );

  CallView _view(Response<dynamic> res) {
    try {
      return CallView.fromJson(_body(res));
    } on FormatException {
      throw CallError(status: res.statusCode, code: 'BAD_RESPONSE');
    }
  }

  /// The response object, bare or under `data`.
  Map<String, dynamic> _body(Response<dynamic> res) {
    final body = res.data;
    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    if (body is Map) return Map<String, dynamic>.from(body);
    throw CallError(status: res.statusCode, code: 'BAD_RESPONSE');
  }

  Future<Response<dynamic>> _guard(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (e) {
      final data = e.response?.data;
      throw CallError(
        status: e.response?.statusCode,
        code: data is Map ? data['code']?.toString() : null,
      );
    }
  }
}
