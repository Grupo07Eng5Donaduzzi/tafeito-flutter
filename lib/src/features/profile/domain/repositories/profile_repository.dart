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

  Future<Result<UserDto>> uploadPhoto({
    required String id,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  });
}
