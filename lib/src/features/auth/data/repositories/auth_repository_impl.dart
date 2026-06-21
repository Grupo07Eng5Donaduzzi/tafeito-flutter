import '../../../../core/network/api_client.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this.remoteDataSource,
  });

  final AuthRemoteDataSource remoteDataSource;

  @override
  Future<Result<AuthSession>> register(RegisterRequest request) async {
    try {
      final response = await remoteDataSource.register(request);
      return Success(response.toEntity());
    } on ApiClientException catch (exception) {
      return Failure(
        _messageOrFallback(
          exception.message,
          'Nao foi possivel criar sua conta agora.',
        ),
      );
    } on Exception {
      return const Failure('Nao foi possivel criar sua conta agora.');
    }
  }

  @override
  Future<Result<AuthSession>> login(LoginRequest request) async {
    try {
      final response = await remoteDataSource.login(request);
      return Success(response.toEntity());
    } on ApiClientException catch (exception) {
      return Failure(
        _messageOrFallback(
          exception.message,
          'Nao foi possivel entrar na sua conta agora.',
        ),
      );
    } on Exception {
      return const Failure('Nao foi possivel entrar na sua conta agora.');
    }
  }
}

String _messageOrFallback(String message, String fallback) {
  final trimmed = message.trim();
  if (trimmed.isEmpty) {
    return fallback;
  }

  return trimmed;
}
