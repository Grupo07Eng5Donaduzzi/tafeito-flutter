import '../../../../core/network/api_client.dart';

abstract interface class ProfileDeleteRemoteDataSource {
  Future<void> deleteUser({required String id});
}

class ApiProfileDeleteRemoteDataSource implements ProfileDeleteRemoteDataSource {
  const ApiProfileDeleteRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<void> deleteUser({required String id}) async {
    await _apiClient.delete('/v1/users/$id');
  }
}

