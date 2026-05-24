import '../../../../core/result/result.dart';
import '../../data/models/update_user_request.dart';
import '../../data/models/user_dto.dart';

abstract interface class ProfileRepository {
  Future<Result<UserDto>> getMe();

  Future<Result<UserDto>> update({
    required String id,
    required UpdateUserRequest request,
  });
}

