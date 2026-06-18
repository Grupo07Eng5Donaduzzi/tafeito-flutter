import '../../../../core/result/result.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/services_repository.dart';
import '../datasources/services_remote_data_source.dart';
import '../models/create_service_request.dart';
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
  Future<Result<List<ServiceDto>>> findMine({required String userId}) async {
    try {
      final services = await _remoteDataSource.findMine(userId: userId);
      return Success(services);
    } on Exception {
      return const Failure('Nao foi possivel carregar seus servicos.');
    }
  }

  @override
  Future<Result<ServiceDto>> create(CreateServiceRequest request) async {
    try {
      final service = await _remoteDataSource.create(request);
      return Success(service);
    } on Exception catch (e) {
      return Failure(_messageFrom(e, 'Nao foi possivel criar o servico.'));
    }
  }

  @override
  Future<Result<ServiceDto>> update(
    String id,
    CreateServiceRequest request,
  ) async {
    try {
      final service = await _remoteDataSource.update(id, request);
      return Success(service);
    } on Exception catch (e) {
      return Failure(_messageFrom(e, 'Nao foi possivel atualizar o servico.'));
    }
  }

  @override
  Future<Result<ServiceDto>> uploadPhoto({
    required String id,
    required MultipartFilePayload photo,
  }) async {
    try {
      final service = await _remoteDataSource.uploadPhoto(id: id, photo: photo);
      return Success(service);
    } on Exception catch (e) {
      return Failure(_messageFrom(e, 'Não foi possível enviar a foto.'));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _remoteDataSource.delete(id);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(_messageFrom(e, 'Nao foi possivel excluir o servico.'));
    }
  }

  String _messageFrom(Exception e, String fallback) {
    final msg = e.toString();
    if (msg.contains('ApiClientException')) {
      final start = msg.indexOf('):') + 2;
      if (start > 1 && start < msg.length) {
        return msg.substring(start).trim();
      }
    }
    return fallback;
  }
}
