import '../../../../core/network/api_client.dart';
import '../models/service_dto.dart';

abstract interface class ServicesRemoteDataSource {
  Future<List<ServiceDto>> findAll({String? category});
}

class ApiServicesRemoteDataSource implements ServicesRemoteDataSource {
  const ApiServicesRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<ServiceDto>> findAll({String? category}) async {
    final response = await _apiClient.get(
      '/v1/services',
      queryParameters: {'category': category},
    );
    final servicesJson = _extractList(response);

    return servicesJson
        .whereType<Map>()
        .map((json) => ServiceDto.fromJson(asJsonObject(json)))
        .toList();
  }

  List<Object?> _extractList(Object? response) {
    final unwrapped = unwrapJsonData(response);
    if (unwrapped is List) {
      return asJsonList(unwrapped);
    }

    if (unwrapped is Map) {
      for (final key in ['items', 'services', 'records']) {
        final value = unwrapped[key];
        if (value is List) {
          return asJsonList(value);
        }
      }
    }

    return asJsonList(unwrapped);
  }
}
