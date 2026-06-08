class PasswordRecoveryCodeRequest {
  const PasswordRecoveryCodeRequest({
    required this.email,
    required this.code,
  });

  final String email;
  final String code;

  Map<String, Object?> toJson() {
    return {
      'email': email,
      'code': code,
    };
  }
}
