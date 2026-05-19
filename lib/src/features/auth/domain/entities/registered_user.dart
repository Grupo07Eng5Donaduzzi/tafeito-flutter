import 'user_type.dart';

class RegisteredUser {
  const RegisteredUser({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
  });

  final String id;
  final String name;
  final String email;
  final UserType userType;
}
