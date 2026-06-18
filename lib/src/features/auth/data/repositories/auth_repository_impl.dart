import '../../../../core/network/api_client.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/password_recovery_remote_data_source.dart';
import '../models/login_request.dart';
import '../models/password_recovery_code_request.dart';
import '../models/password_recovery_email_request.dart';
import '../models/password_reset_request.dart';
import '../models/register_request.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.passwordRecoveryRemoteDataSource,
  });

  final AuthRemoteDataSource remoteDataSource;
  final PasswordRecoveryRemoteDataSource passwordRecoveryRemoteDataSource;

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

  @override
  Future<Result<void>> requestPasswordResetCode({
    required String email,
  }) async {
    try {
      await passwordRecoveryRemoteDataSource.requestPasswordResetCode(
        PasswordRecoveryEmailRequest(email: email.trim()),
      );
      return const Success(null);
    } on Exception {
      return const Failure('Nao foi possivel enviar o codigo agora.');
    }
  }

  @override
  Future<Result<void>> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    try {
      await passwordRecoveryRemoteDataSource.verifyPasswordResetCode(
        PasswordRecoveryCodeRequest(
          email: email.trim(),
          code: code.trim(),
        ),
      );
      return const Success(null);
    } on Exception {
      return const Failure('Codigo invalido ou expirado.');
    }
  }

  @override
  Future<Result<void>> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await passwordRecoveryRemoteDataSource.confirmPasswordReset(
        PasswordResetRequest(
          email: email.trim(),
          code: code.trim(),
          newPassword: newPassword,
        ),
      );
      return const Success(null);
    } on Exception {
      return const Failure('Nao foi possivel redefinir sua senha agora.');
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
