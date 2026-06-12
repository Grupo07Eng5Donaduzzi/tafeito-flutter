import '../../../../core/network/api_client.dart';
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

  @override
  Future<Result<ServiceDto>> updateService(
    String id, {
    String? name,
    String? description,
    String? category,
    String? price,
    String? duration,
  }) async {
    final fields = <String, Object?>{
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (price != null) 'price': price,
      if (duration != null) 'duration': duration,
    };

    try {
      final service = await _remoteDataSource.update(id, fields);
      return Success(service);
    } on ApiClientException catch (error) {
      return Failure(error.message);
    } on Exception {
      return const Failure('Nao foi possivel salvar o servico agora.');
    }
  }
}
