import 'package:tafeito_flutter/src/features/profile/data/models/update_user_request.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/user_dto.dart';

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
    final response = await _apiClient.get('/v1/users/me');
    return UserDto.fromJson(asJsonObject(unwrapJsonData(response)));
  }

  @override
  Future<UserDto> update({
    required String id,
    required UpdateUserRequest request,
  }) async {
    await _apiClient.put(
      '/v1/users/$id',
      body: request.toJson(),
    );

    return getMe();
  }
}
