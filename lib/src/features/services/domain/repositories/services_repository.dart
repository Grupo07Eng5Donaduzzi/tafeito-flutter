import '../../../../core/result/result.dart';
import '../../data/models/service_dto.dart';

abstract interface class ServicesRepository {
  Future<Result<List<ServiceDto>>> findAll({String? category});
}
