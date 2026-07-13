import 'package:massdrive/features/auth/domain/entities/otp_response.dart';

class OtpResponseModel {
  final bool isRegistered;
  final String message;
  final String refId;

  const OtpResponseModel({
    required this.isRegistered,
    required this.message,
    required this.refId,
  });

  factory OtpResponseModel.fromJson(Map<String, dynamic> json) {
    return OtpResponseModel(
      isRegistered: json['is_registered'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      refId: json['ref_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_registered': isRegistered,
      'message': message,
      'ref_id': refId,
    };
  }
}

extension OtpResponseMapper on OtpResponseModel {
  OtpResponse toEntity() {
    return OtpResponse(
      isRegistered: isRegistered,
      message: message,
      refId: refId,
    );
  }
}

