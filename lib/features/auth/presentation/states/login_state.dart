class LoginState {
  final String identity;

  const LoginState({this.identity = ''});

  LoginState copyWith({String? identity, String? errorMessage}) {
    return LoginState(identity: identity ?? this.identity);
  }
}
