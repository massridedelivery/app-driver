class EmailLoginState {
  final String email;
  final String password;
  final bool isLoading;
  final String errorMessage;

  const EmailLoginState({
    this.email = '',
    this.password = '',
    this.isLoading = false,
    this.errorMessage = '',
  });

  EmailLoginState copyWith({
    String? email,
    String? password,
    bool? isLoading,
    String? errorMessage,
  }) {
    return EmailLoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
