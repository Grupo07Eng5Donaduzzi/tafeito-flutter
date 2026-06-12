import '../../../../core/result/result.dart';
import '../../data/models/service_dto.dart';

abstract interface class ServicesRepository {
  Future<Result<List<ServiceDto>>> findAll({String? category});
  Future<Result<ServiceDto>> updateService(
    String id, {
    String? name,
    String? description,
    String? category,
    String? price,
    String? duration,
  });
}
