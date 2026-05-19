import '../../../../core/network/api_client.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';

abstract interface class AuthRemoteDataSource {
  Future<RegisterResponse> register(RegisterRequest request);

  Future<RegisterResponse> login(LoginRequest request);
}

class ApiAuthRemoteDataSource implements AuthRemoteDataSource {
  const ApiAuthRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<RegisterResponse> register(RegisterRequest request) async {
    final json = await _apiClient.post(
      '/auth/register',
      body: request.toJson(),
    );

    return RegisterResponse.fromJson(json);
  }

  @override
  Future<RegisterResponse> login(LoginRequest request) async {
    final json = await _apiClient.post(
      '/auth/login',
      body: request.toJson(),
    );

    return RegisterResponse.fromJson(json);
  }
}

class StubAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<RegisterResponse> register(RegisterRequest request) async {
    // TODO: substituir por chamada HTTP quando o endpoint de cadastro existir.
    await Future<void>.delayed(const Duration(milliseconds: 700));

    return RegisterResponse(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: request.name,
      email: request.email,
      userType: request.userType,
    );
  }

  @override
  Future<RegisterResponse> login(LoginRequest request) async {
    // TODO: substituir por chamada HTTP quando o endpoint de login existir.
    await Future<void>.delayed(const Duration(milliseconds: 700));

    return RegisterResponse(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Usuario',
      email: request.email,
      userType: request.userType,
    );
  }
}
