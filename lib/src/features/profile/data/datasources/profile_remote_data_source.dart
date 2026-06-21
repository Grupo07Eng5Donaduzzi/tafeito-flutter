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

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  });

  Future<void> deleteAccount({required String id});

  Future<UserDto> becomeProvider({required String pixKey});

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
  Future<UserDto> becomeProvider({required String pixKey}) async {
    await _apiClient.patch(
      ApiPaths.becomeProvider,
      body: {'pixKey': pixKey},
    );

    return getMe();
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    await _apiClient.patch(
      ApiPaths.changePassword,
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      },
    );
  }

  @override
  Future<void> deleteAccount({required String id}) async {
    await _apiClient.delete(ApiPaths.user(id));
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
