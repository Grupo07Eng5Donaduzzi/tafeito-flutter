import '../../domain/entities/registered_user.dart';
import '../../domain/entities/user_type.dart';

class RegisterResponse {
  const RegisterResponse({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
  });

  final String id;
  final String name;
  final String email;
  final UserType userType;

  factory RegisterResponse.fromJson(Map<String, Object?> json) {
    final userTypeName = json['userType'] as String? ?? UserType.client.name;

    return RegisterResponse(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      userType: UserType.values.firstWhere(
        (type) => type.name == userTypeName,
        orElse: () => UserType.client,
      ),
    );
  }

  RegisteredUser toEntity() {
    return RegisteredUser(
      id: id,
      name: name,
      email: email,
      userType: userType,
    );
  }
}
