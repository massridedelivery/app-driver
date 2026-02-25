import 'package:freezed_annotation/freezed_annotation.dart';

part 'socket_message_model.freezed.dart';

@freezed
sealed class SocketMessageModel with _$SocketMessageModel {
  const factory SocketMessageModel({
    required String type,
    Map<String, dynamic>? data,
    @Default({}) Map<String, dynamic> raw,
  }) = _SocketMessageModel;

  factory SocketMessageModel.fromJson(Map<String, dynamic> json) {
    return SocketMessageModel(
      type: json['type'] as String? ?? 'unknown',
      data: json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : null,
      raw: json,
    );
  }
}
