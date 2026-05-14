import '../../../../core/result/result.dart';
import '../../domain/entities/registered_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required this.remoteDataSource});

  final AuthRemoteDataSource remoteDataSource;

  @override
  Future<Result<RegisteredUser>> register(RegisterRequest request) async {
    try {
      final response = await remoteDataSource.register(request);
      return Success(response.toEntity());
    } on Exception {
      return const Failure('Nao foi possivel criar sua conta agora.');
    }
  }

  @override
  Future<Result<RegisteredUser>> login(LoginRequest request) async {
    try {
      final response = await remoteDataSource.login(request);
      return Success(response.toEntity());
    } on Exception {
      return const Failure('Nao foi possivel entrar na sua conta agora.');
    }
  }
}
