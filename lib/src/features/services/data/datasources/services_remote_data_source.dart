import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../models/create_service_request.dart';
import '../models/service_dto.dart';

abstract interface class ServicesRemoteDataSource {
  Future<List<ServiceDto>> findAll({String? category});
  Future<List<ServiceDto>> findMine({required String userId});
  Future<ServiceDto> create(CreateServiceRequest request);
  Future<ServiceDto> update(String id, CreateServiceRequest request);
  Future<ServiceDto> uploadPhoto({
    required String id,
    required MultipartFilePayload photo,
  });
  Future<void> delete(String id);
}

class ApiServicesRemoteDataSource implements ServicesRemoteDataSource {
  const ApiServicesRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<ServiceDto>> findAll({String? category}) async {
    final response = await _apiClient.get(
      ApiPaths.services,
      queryParameters: {
        'page': '1',
        'limit': '100',
        'category': category,
      },
    );
    return _extractList(response);
  }

  @override
  Future<List<ServiceDto>> findMine({required String userId}) async {
    final response = await _apiClient.get(ApiPaths.services);
    final all = _extractList(response);
    return all.where((s) => s.providerId == userId).toList();
  }

  @override
  Future<ServiceDto> create(CreateServiceRequest request) async {
    final response = await _apiClient.post(
      ApiPaths.services,
      body: request.toJson(),
    );
    return ServiceDto.fromJson(asJsonObject(unwrapJsonData(response)));
  }

  @override
  Future<ServiceDto> update(String id, CreateServiceRequest request) async {
    final response = await _apiClient.put(
      ApiPaths.service(id),
      body: request.toJson(),
    );
    final unwrapped = unwrapJsonData(response);
    if (unwrapped is Map && unwrapped.isNotEmpty) {
      return ServiceDto.fromJson(asJsonObject(unwrapped));
    }

    final updated = await _apiClient.get(ApiPaths.service(id));
    return ServiceDto.fromJson(asJsonObject(unwrapJsonData(updated)));
  }

  @override
  Future<ServiceDto> uploadPhoto({
    required String id,
    required MultipartFilePayload photo,
  }) async {
    final response = await _apiClient.multipartPost(
      ApiPaths.servicePhoto(id),
      files: [photo],
    );
    return ServiceDto.fromJson(asJsonObject(unwrapJsonData(response)));
  }

  @override
  Future<void> delete(String id) async {
    await _apiClient.delete(ApiPaths.service(id));
  }

  List<ServiceDto> _extractList(Object? response) {
    final unwrapped = unwrapJsonData(response);
    if (unwrapped is List) {
      return asJsonList(unwrapped)
          .whereType<Map>()
          .map((json) => ServiceDto.fromJson(asJsonObject(json)))
          .toList();
    }

    if (unwrapped is Map) {
      for (final key in ['items', 'services', 'records', 'data']) {
        final value = unwrapped[key];
        if (value is List) {
          return asJsonList(value)
              .whereType<Map>()
              .map((json) => ServiceDto.fromJson(asJsonObject(json)))
              .toList();
        }
      }
    }

    return [];
  }
}
