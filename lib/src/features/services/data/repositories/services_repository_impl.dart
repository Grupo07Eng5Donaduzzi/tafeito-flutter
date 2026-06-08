import '../../../../core/result/result.dart';
import '../../domain/repositories/services_repository.dart';
import '../datasources/services_remote_data_source.dart';
import '../models/service_dto.dart';

class ServicesRepositoryImpl implements ServicesRepository {
  const ServicesRepositoryImpl(
      {required ServicesRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final ServicesRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<ServiceDto>>> findAll({String? category}) async {
    try {
      final services = await _remoteDataSource.findAll(category: category);
      return Success(services);
    } on Exception {
      return const Failure('Nao foi possivel carregar os servicos agora.');
    }
  }
}
