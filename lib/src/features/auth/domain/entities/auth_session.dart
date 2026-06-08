import 'dart:convert';

import 'registered_user.dart';
import 'user_type.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.user,
    this.expiresAt,
  });

  final String accessToken;
  final RegisteredUser user;
  final DateTime? expiresAt;

  bool isValid({DateTime? now}) {
    final token = accessToken.trim();
    final expiration = expiresAt ?? _expiresAtFromJwt(token);

    if (token.isEmpty) {
      return false;
    }

    if (expiration == null) {
      return true;
    }

    return expiration.isAfter(now ?? DateTime.now());
  }

  Map<String, Object?> toJson() {
    return {
      'accessToken': accessToken,
      'expiresAt': expiresAt?.toIso8601String(),
      'user': {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'userType': user.userType.name,
      },
    };
  }

  factory AuthSession.fromJson(Map<String, Object?> json) {
    final userJson = _asObjectMap(json['user']);
    final userTypeName = userJson['userType']?.toString() ?? '';

    return AuthSession(
      accessToken: json['accessToken']?.toString() ?? '',
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
      user: RegisteredUser(
        id: userJson['id']?.toString() ?? '',
        name: userJson['name']?.toString() ?? '',
        email: userJson['email']?.toString() ?? '',
        userType: UserType.values.firstWhere(
          (type) => type.name == userTypeName,
          orElse: () => UserType.client,
        ),
      ),
    );
  }

  static DateTime? _expiresAtFromJwt(String token) {
    final parts = token.split('.');
    if (parts.length < 2) {
      return null;
    }

    try {
      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final json = jsonDecode(payload);
      if (json is! Map<String, Object?>) {
        return null;
      }

      final exp = json['exp'];
      final seconds = switch (exp) {
        int value => value,
        num value => value.toInt(),
        String value => int.tryParse(value),
        _ => null,
      };

      if (seconds == null) {
        return null;
      }

      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    } on Object {
      return null;
    }
  }
}

Map<String, Object?> _asObjectMap(Object? value) {
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  return const {};
}
