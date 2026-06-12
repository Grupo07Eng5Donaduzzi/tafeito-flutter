import '../../../../core/result/result.dart';
import '../../data/models/service_dto.dart';

abstract interface class ServicesRepository {
  Future<Result<List<ServiceDto>>> findAll({String? category});
  Future<Result<List<String>>> loadCategories();
  Future<Result<ServiceDto>> createService({
    required String name,
    required String description,
    required String category,
    required String price,
    required String pricingType,
  });
  Future<Result<void>> updateService(
    String id, {
    String? name,
    String? description,
    String? category,
    String? price,
    String? pricingType,
  });
}
