import '../../../../core/result/result.dart';
import '../../data/datasources/profile_delete_remote_data_source.dart';
import '../../domain/repositories/profile_delete_repository.dart';

class ProfileDeleteRepositoryImpl implements ProfileDeleteRepository {
  const ProfileDeleteRepositoryImpl({required this.remoteDataSource});

  final ProfileDeleteRemoteDataSource remoteDataSource;

  @override
  Future<Result<void>> deleteAccount({required String id}) async {
    try {
      await remoteDataSource.deleteUser(id: id);
      return const Success(null);
    } on Exception {
      return const Failure('Nao foi possivel excluir sua conta agora.');
    }
  }
}

