import '../../../../core/result/result.dart';

abstract interface class ProfileDeleteRepository {
  Future<Result<void>> deleteAccount({required String id});
}

