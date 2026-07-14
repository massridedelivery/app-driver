class LoginState {
  final String phoneNumber;
  final bool isLoading;
  final String? errorMessage;
  final String refId;
  final bool isRegistered;

  const LoginState({
    this.phoneNumber = '',
    this.isLoading = false,
    this.errorMessage,
    this.refId = '',
    this.isRegistered = false,
  });

  LoginState copyWith({
    String? phoneNumber,
    bool? isLoading,
    String? errorMessage,
    String? refId,
    bool? isRegistered,
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
    );
  }
}

