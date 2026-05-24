import '../../../../core/result/result.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/models/update_user_request.dart';
import '../../data/models/user_dto.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({required this.remoteDataSource});

  final ProfileRemoteDataSource remoteDataSource;

  @override
  Future<Result<UserDto>> getMe() async {
    try {
      final user = await remoteDataSource.getMe();
      return Success(user);
    } on Exception {
      return const Failure('Nao foi possivel carregar seu perfil agora.');
    }
  }

  @override
  Future<Result<UserDto>> update({
    required String id,
    required UpdateUserRequest request,
  }) async {
    try {
      final user = await remoteDataSource.update(id: id, request: request);
      return Success(user);
    } on Exception {
      return const Failure('Nao foi possivel salvar suas alteracoes agora.');
    }
  }
}

