import '../../../../core/result/result.dart';
import '../../data/models/login_request.dart';
import '../../data/models/register_request.dart';
import '../entities/registered_user.dart';

abstract interface class AuthRepository {
  Future<Result<RegisteredUser>> register(RegisterRequest request);

  Future<Result<RegisteredUser>> login(LoginRequest request);
}
