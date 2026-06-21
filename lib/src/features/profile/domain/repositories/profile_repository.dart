import 'dart:typed_data';

import '../../../../core/result/result.dart';
import '../../data/models/update_user_request.dart';
import '../../data/models/user_dto.dart';

abstract interface class ProfileRepository {
  Future<Result<UserDto>> getMe();

  Future<Result<UserDto>> update({
    required String id,
    required UpdateUserRequest request,
  });

  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  });

  Future<Result<void>> deleteAccount({required String id});

  Future<Result<UserDto>> becomeProvider({required String pixKey});

  Future<Result<UserDto>> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  });
}
