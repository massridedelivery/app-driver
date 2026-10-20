class LoginState {
  final String phoneNumber;
  final bool isLoading;
  final String? errorMessage;
  final String refId;
  final bool isRegistered;

  /// Set when /otp/send was rate-limited: how long until it may be asked again.
  final Duration? retryAfter;

  const LoginState({
    this.phoneNumber = '',
    this.isLoading = false,
    this.errorMessage,
    this.refId = '',
    this.isRegistered = false,
    this.retryAfter,
  });

  LoginState copyWith({
    String? phoneNumber,
    bool? isLoading,
    String? errorMessage,
    String? refId,
    bool? isRegistered,
    Duration? retryAfter,
    bool clearRetryAfter = false,
  }) {
    // We want to allow null for errorMessage to clear it
    return LoginState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null
          ? (errorMessage.isEmpty ? null : errorMessage)
          : this.errorMessage,
      refId: refId ?? this.refId,
      isRegistered: isRegistered ?? this.isRegistered,
      retryAfter: clearRetryAfter ? null : (retryAfter ?? this.retryAfter),
    );
  }
}
