import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../models/auth_session_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthSessionResponse> register(RegisterRequest request);

  Future<AuthSessionResponse> login(LoginRequest request);
}

class ApiAuthRemoteDataSource implements AuthRemoteDataSource {
  const ApiAuthRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<AuthSessionResponse> register(RegisterRequest request) async {
    final response = await _apiClient.post(
      ApiPaths.authRegister,
      body: request.toJson(),
    );

    return AuthSessionResponse.fromJson(asJsonObject(response));
  }

  @override
  Future<AuthSessionResponse> login(LoginRequest request) async {
    final response = await _apiClient.post(
      ApiPaths.authLogin,
      body: request.toJson(),
    );

    return AuthSessionResponse.fromJson(asJsonObject(response));
  }
}

class StubAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<AuthSessionResponse> register(RegisterRequest request) async {

    await Future<void>.delayed(const Duration(milliseconds: 700));
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final expiresAt = DateTime.now().add(const Duration(days: 30));

    return AuthSessionResponse(
      accessToken: _FakeJwtFactory.create(
        subject: id,
        email: request.email,
        expiresAt: expiresAt,
      ),
      userId: id,
      name: request.name,
      email: request.email,
      userType: request.userType,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<AuthSessionResponse> login(LoginRequest request) async {

    await Future<void>.delayed(const Duration(milliseconds: 700));
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final expiresAt = DateTime.now().add(const Duration(days: 30));

    return AuthSessionResponse(
      accessToken: _FakeJwtFactory.create(
        subject: id,
        email: request.email,
        expiresAt: expiresAt,
      ),
      userId: id,
      name: 'Usuario',
      email: request.email,
      userType: request.userType,
      expiresAt: expiresAt,
    );
  }
}

class _FakeJwtFactory {
  const _FakeJwtFactory._();

  static String create({
    required String subject,
    required String email,
    required DateTime expiresAt,
  }) {
    final header = _encode({
      'alg': 'none',
      'typ': 'JWT',
    });
    final payload = _encode({
      'sub': subject,
      'email': email,
      'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
    });

    return '$header.$payload.stub-signature';
  }

  static String _encode(Map<String, Object?> json) {
    return base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  }
}
