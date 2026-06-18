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

  Future<Result<UserDto>> becomeProvider({
    required String pixKey,
    required double hourlyRate,
  });

  Future<Result<UserDto>> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  });
}
