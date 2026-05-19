import '../../domain/entities/user_type.dart';

class LoginRequest {
  const LoginRequest({
    required this.email,
    required this.password,
    this.userType = UserType.client,
  });

  final String email;
  final String password;
  final UserType userType;

  Map<String, Object?> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}
