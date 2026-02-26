class RegisterRequest {
  final String email;
  final String fullName;
  final String password;
  final String phone;
  final String role;

  const RegisterRequest({
    required this.email,
    required this.fullName,
    required this.password,
    required this.phone,
    required this.role,
  });
}
