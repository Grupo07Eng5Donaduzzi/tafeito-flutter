import '../../../../core/result/result.dart';
import '../../data/models/create_service_request.dart';
import '../../data/models/service_dto.dart';

abstract interface class ServicesRepository {
  Future<Result<List<ServiceDto>>> findAll({String? category});
  Future<Result<List<ServiceDto>>> findMine({required String userId});
  Future<Result<ServiceDto>> create(CreateServiceRequest request);
  Future<Result<ServiceDto>> update(String id, CreateServiceRequest request);
  Future<Result<void>> delete(String id);
}
