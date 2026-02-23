class OtpState {
  final String otpCode;
  final bool isLoading;
  final String? errorMessage;

  const OtpState({
    this.otpCode = '',
    this.isLoading = false,
    this.errorMessage,
  });

  OtpState copyWith({
    String? otpCode,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OtpState(
      otpCode: otpCode ?? this.otpCode,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? (errorMessage.isEmpty ? null : errorMessage) : this.errorMessage,
    );
  }
}
