import 'dart:typed_data';

import 'package:tafeito_flutter/src/features/profile/data/models/update_user_request.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../../data/models/user_dto.dart';

abstract interface class ProfileRemoteDataSource {
  Future<UserDto> getMe();

  Future<UserDto> update({
    required String id,
    required UpdateUserRequest request,
  });

  Future<UserDto> becomeProvider({
    required String pixKey,
    required double hourlyRate,
  });

  Future<UserDto> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  });
}

class ApiProfileRemoteDataSource implements ProfileRemoteDataSource {
  const ApiProfileRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<UserDto> getMe() async {
    final response = await _apiClient.get(ApiPaths.me);
    return UserDto.fromJson(asJsonObject(unwrapJsonData(response)));
  }

  @override
  Future<UserDto> update({
    required String id,
    required UpdateUserRequest request,
  }) async {
    await _apiClient.put(
      ApiPaths.user(id),
      body: request.toJson(),
    );

    return getMe();
  }

  @override
  Future<UserDto> becomeProvider({
    required String pixKey,
    required double hourlyRate,
  }) async {
    await _apiClient.patch(
      ApiPaths.becomeProvider,
      body: {
        'pixKey': pixKey,
        'hourlyRate': hourlyRate,
      },
    );

    return getMe();
  }

  @override
  Future<UserDto> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final response = await _apiClient.multipartPost(
      ApiPaths.myAvatar,
      files: [
        MultipartFilePayload(
          fieldName: 'avatar',
          fileName: fileName,
          bytes: bytes,
        ),
      ],
    );
    return UserDto.fromJson(asJsonObject(unwrapJsonData(response)));
  }
}
