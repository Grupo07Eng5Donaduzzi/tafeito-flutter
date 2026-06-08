import '../../domain/entities/auth_session.dart';
import '../../domain/entities/registered_user.dart';
import '../../domain/entities/user_type.dart';

class AuthSessionResponse {
  const AuthSessionResponse({
    required this.accessToken,
    required this.userId,
    required this.name,
    required this.email,
    required this.userType,
    this.expiresAt,
  });

  final String accessToken;
  final String userId;
  final String name;
  final String email;
  final UserType userType;
  final DateTime? expiresAt;

  factory AuthSessionResponse.fromJson(Map<String, Object?> json) {
    final dataJson = _asObjectMap(json['data']);
    final sessionJson = dataJson.isEmpty ? json : dataJson;
    final userJson = _asObjectMap(sessionJson['user']);
    final userTypeName = _firstString(
      userJson['userType'],
      userJson['type'],
      userJson['role'],
      sessionJson['userType'],
      sessionJson['type'],
      sessionJson['role'],
      UserType.client.name,
    );

    return AuthSessionResponse(
      accessToken: _firstString(
        sessionJson['accessToken'],
        sessionJson['access_token'],
        sessionJson['token'],
        sessionJson['jwt'],
      ),
      userId: _firstString(userJson['id'], sessionJson['id'], ''),
      name: _firstString(userJson['name'], sessionJson['name'], ''),
      email: _firstString(userJson['email'], sessionJson['email'], ''),
      userType: UserType.values.firstWhere(
        (type) => type.name == userTypeName,
        orElse: () => UserType.client,
      ),
      expiresAt: _parseExpiresAt(sessionJson),
    );
  }

  AuthSession toEntity() {
    return AuthSession(
      accessToken: accessToken,
      expiresAt: expiresAt,
      user: RegisteredUser(
        id: userId,
        name: name,
        email: email,
        userType: userType,
      ),
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
  Object? fifth,
  Object? sixth,
  Object? seventh,
]) {
  for (final value in [
    first,
    second,
    third,
    fourth,
    fifth,
    sixth,
    seventh,
  ]) {
    final text = value?.toString();
    if (text != null && text.isNotEmpty) {
      return text;
    }
  }

  return '';
}

DateTime? _parseExpiresAt(Map<String, Object?> json) {
  final expiresAt = DateTime.tryParse(json['expiresAt']?.toString() ?? '');
  if (expiresAt != null) {
    return expiresAt;
  }

  final expiresIn = json['expiresIn'];
  final seconds = switch (expiresIn) {
    int value => value,
    num value => value.toInt(),
    String value => int.tryParse(value),
    _ => null,
  };

  if (seconds == null) {
    return null;
  }

  return DateTime.now().add(Duration(seconds: seconds));
}
