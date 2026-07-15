class OtpResponse {
  final bool isRegistered;
  final String message;
  final String refId;

  const OtpResponse({
    required this.isRegistered,
    required this.message,
    required this.refId,
  });
}
