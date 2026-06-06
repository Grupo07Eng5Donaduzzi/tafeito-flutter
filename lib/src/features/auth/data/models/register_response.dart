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
    final userJson = _asObjectMap(json['user']);
    final registerJson = userJson.isEmpty ? json : userJson;
    final userTypeName = _firstString(
      registerJson['userType'],
      registerJson['type'],
      registerJson['role'],
      UserType.client.name,
    );

    return RegisterResponse(
      id: registerJson['id']?.toString() ?? '',
      name: registerJson['name']?.toString() ?? '',
      email: registerJson['email']?.toString() ?? '',
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

Map<String, Object?> _asObjectMap(Object? value) {
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  return const {};
}

String _firstString(
  Object? first, [
  Object? second,
  Object? third,
  Object? fourth,
]) {
  for (final value in [first, second, third, fourth]) {
    final text = value?.toString();
    if (text != null && text.isNotEmpty) {
      return text;
    }
  }

  return '';
}
