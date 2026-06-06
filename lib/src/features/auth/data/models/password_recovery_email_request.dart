class PasswordRecoveryEmailRequest {
  const PasswordRecoveryEmailRequest({required this.email});

  final String email;

  Map<String, Object?> toJson() {
    return {'email': email};
  }
}
