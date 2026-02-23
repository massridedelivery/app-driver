import 'package:json_annotation/json_annotation.dart';
import 'package:massdrive/features/auth/domain/entities/auth_token.dart';

part 'auth_token_model.g.dart';

@JsonSerializable(createToJson: true, fieldRename: FieldRename.snake)
class AuthTokenModel {
  final String? accessToken;
  final String? refreshToken;

  const AuthTokenModel({this.accessToken, this.refreshToken});

  factory AuthTokenModel.fromJson(Map<String, dynamic> json) =>
      _$AuthTokenModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthTokenModelToJson(this);
}

extension AuthTokenMapper on AuthTokenModel {
  AuthToken toEntity() => AuthToken(
    accessToken: accessToken ?? '',
    refreshToken: refreshToken ?? '',
  );
}
