import 'package:json_annotation/json_annotation.dart';
import 'package:massdrive/features/auth/domain/entities/register_request.dart';

part 'register_request_model.g.dart';

@JsonSerializable(createToJson: true, fieldRename: FieldRename.snake)
class RegisterRequestModel {
  final String email;
  final String fullName;
  final String password;
  final String phone;
  final String role;
  final String appVersion;
  final String deviceId;
  final String deviceModel;
  final String integrityToken;
  final String os;
  final String osVersion;

  const RegisterRequestModel({
    required this.email,
    required this.fullName,
    required this.password,
    required this.phone,
    required this.role,
    required this.appVersion,
    required this.deviceId,
    required this.deviceModel,
    required this.integrityToken,
    required this.os,
    required this.osVersion,
  });

  factory RegisterRequestModel.fromEntity(RegisterRequest entity) {
    return RegisterRequestModel(
      email: entity.email,
      fullName: entity.fullName,
      password: entity.password,
      phone: entity.phone,
      role: entity.role,
      appVersion: entity.appVersion,
      deviceId: entity.deviceId,
      deviceModel: entity.deviceModel,
      integrityToken: entity.integrityToken,
      os: entity.os,
      osVersion: entity.osVersion,
    );
  }

  Map<String, dynamic> toJson() => _$RegisterRequestModelToJson(this);
}
