class LoginState {
  final String phoneNumber;
  final bool isLoading;
  final String? errorMessage;

  const LoginState({
    this.phoneNumber = '',
    this.isLoading = false,
    this.errorMessage,
  });

  LoginState copyWith({
    String? phoneNumber,
    bool? isLoading,
    String? errorMessage,
  }) {
    // We want to allow null for errorMessage to clear it
    return LoginState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null
          ? (errorMessage.isEmpty ? null : errorMessage)
          : this.errorMessage,
    );
  }
}
