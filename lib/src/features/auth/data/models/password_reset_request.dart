class PasswordResetRequest {
  const PasswordResetRequest({
    required this.email,
    required this.code,
    required this.newPassword,
  });

  final String email;
  final String code;
  final String newPassword;

  Map<String, Object?> toJson() {
    return {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    };
  }
}
