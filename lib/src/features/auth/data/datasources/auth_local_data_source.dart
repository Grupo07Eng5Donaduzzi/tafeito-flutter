import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/auth_session.dart';

abstract interface class AuthLocalDataSource {
  Future<AuthSession?> readSession();

  Future<void> saveSession(AuthSession session);

  Future<void> clearSession();
}

class SecureAuthLocalDataSource implements AuthLocalDataSource {
  SecureAuthLocalDataSource({
    FlutterSecureStorage? secureStorage,
    AuthLocalDataSource? fallbackDataSource,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _fallbackDataSource =
            fallbackDataSource ?? InMemoryAuthLocalDataSource();

  static const _sessionKey = 'auth_session';

  final FlutterSecureStorage _secureStorage;
  final AuthLocalDataSource _fallbackDataSource;
  bool _useFallback = false;

  @override
  Future<AuthSession?> readSession() {
    return _guard(
      secureAction: () async {
        final payload = await _secureStorage.read(key: _sessionKey);
        if (payload == null || payload.isEmpty) {
          return null;
        }

        final json = jsonDecode(payload);
        if (json is! Map<String, Object?>) {
          return null;
        }

        return AuthSession.fromJson(json);
      },
      fallbackAction: _fallbackDataSource.readSession,
    );
  }

  @override
  Future<void> saveSession(AuthSession session) {
    return _guard(
      secureAction: () {
        return _secureStorage.write(
          key: _sessionKey,
          value: jsonEncode(session.toJson()),
        );
      },
      fallbackAction: () => _fallbackDataSource.saveSession(session),
    );
  }

  @override
  Future<void> clearSession() {
    return _guard(
      secureAction: () => _secureStorage.delete(key: _sessionKey),
      fallbackAction: _fallbackDataSource.clearSession,
    );
  }

  Future<T> _guard<T>({
    required Future<T> Function() secureAction,
    required Future<T> Function() fallbackAction,
  }) async {
    if (_useFallback) {
      return fallbackAction();
    }

    try {
      return await secureAction();
    } on Object {
      _useFallback = true;
      return fallbackAction();
    }
  }
}

class InMemoryAuthLocalDataSource implements AuthLocalDataSource {
  AuthSession? _session;

  @override
  Future<AuthSession?> readSession() async => _session;

  @override
  Future<void> saveSession(AuthSession session) async {
    _session = session;
  }

  @override
  Future<void> clearSession() async {
    _session = null;
  }
}
