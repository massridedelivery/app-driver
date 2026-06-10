class RegisterRequest {
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

  const RegisterRequest({
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
}
