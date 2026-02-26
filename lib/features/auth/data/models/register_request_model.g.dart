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
);

Map<String, dynamic> _$RegisterRequestModelToJson(
  RegisterRequestModel instance,
) => <String, dynamic>{
  'email': instance.email,
  'full_name': instance.fullName,
  'password': instance.password,
  'phone': instance.phone,
  'role': instance.role,
};
