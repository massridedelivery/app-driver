class OtpState {
  final String otpCode;
  final bool isLoading;
  final String? errorMessage;

  /// The last verify said this code is dead (expired / replaced / too many
  /// tries): offer a new OTP straight away.
  final bool needsNewCode;

  const OtpState({
    this.otpCode = '',
    this.isLoading = false,
    this.errorMessage,
    this.needsNewCode = false,
  });

  OtpState copyWith({
    String? otpCode,
    bool? isLoading,
    String? errorMessage,
    bool? needsNewCode,
  }) {
    return OtpState(
      otpCode: otpCode ?? this.otpCode,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null
          ? (errorMessage.isEmpty ? null : errorMessage)
          : this.errorMessage,
      needsNewCode: needsNewCode ?? this.needsNewCode,
    );
  }
}
