// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterRequestModel _$RegisterRequestModelFromJson(
  Map<String, dynamic> json,
) => RegisterRequestModel(
  email: json['email'] as String,
  fullName: json['full_name'] as String,
  password: json['password'] as String,
  phone: json['phone'] as String,
  role: json['role'] as String,
  appVersion: json['app_version'] as String,
  deviceId: json['device_id'] as String,
  deviceModel: json['device_model'] as String,
  integrityToken: json['integrity_token'] as String,
  os: json['os'] as String,
  osVersion: json['os_version'] as String,
);

Map<String, dynamic> _$RegisterRequestModelToJson(
  RegisterRequestModel instance,
) => <String, dynamic>{
  'email': instance.email,
  'full_name': instance.fullName,
  'password': instance.password,
  'phone': instance.phone,
  'role': instance.role,
  'app_version': instance.appVersion,
  'device_id': instance.deviceId,
  'device_model': instance.deviceModel,
  'integrity_token': instance.integrityToken,
  'os': instance.os,
  'os_version': instance.osVersion,
};
