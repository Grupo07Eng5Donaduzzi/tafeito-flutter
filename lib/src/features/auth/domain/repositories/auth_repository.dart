import '../../../../core/result/result.dart';
import '../../data/models/login_request.dart';
import '../../data/models/register_request.dart';
import '../entities/auth_session.dart';

abstract interface class AuthRepository {
  Future<Result<AuthSession>> register(RegisterRequest request);

  Future<Result<AuthSession>> login(LoginRequest request);
}
