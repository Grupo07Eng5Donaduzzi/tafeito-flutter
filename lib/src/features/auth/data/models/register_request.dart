import '../../domain/entities/user_type.dart';

class RegisterRequest {
  const RegisterRequest({
    required this.name,
    required this.document,
    required this.email,
    required this.password,
    required this.userType,
  });

  final String name;
  final String document;
  final String email;
  final String password;
  final UserType userType;

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'document': document,
      'email': email,
      'password': password,
      'userType': userType.name,
    };
  }
}
