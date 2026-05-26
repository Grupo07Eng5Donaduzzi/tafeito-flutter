import '../../../../core/network/api_client.dart';
import '../../data/models/user_dto.dart';
import 'package:tafeito_flutter/src/features/profile/data/models/update_user_request.dart';

abstract interface class ProfileRemoteDataSource {
  Future<UserDto> getMe();

  Future<UserDto> update({
    required String id,
    required UpdateUserRequest request,
  });
}

class ApiProfileRemoteDataSource implements ProfileRemoteDataSource {
  const ApiProfileRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<UserDto> getMe() async {
    final json = await _apiClient.post('/users/me');
    return UserDto.fromJson(json);
  }

  @override
  Future<UserDto> update({
    required String id,
    required UpdateUserRequest request,
  }) async {
    final json = await _apiClient.post('/users/update/$id',
        body: request.toJson());
    return UserDto.fromJson(json);
  }
}

