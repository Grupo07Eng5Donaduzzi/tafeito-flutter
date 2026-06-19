import 'dart:typed_data';

import '../../../../core/network/api_client.dart';
import '../../../../core/result/result.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/models/update_user_request.dart';
import '../../data/models/user_dto.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({required this.remoteDataSource});

  final ProfileRemoteDataSource remoteDataSource;

  @override
  Future<Result<UserDto>> getMe() async {
    try {
      final user = await remoteDataSource.getMe();
      return Success(user);
    } on Exception {
      return const Failure('Não foi possível carregar seu perfil agora.');
    }
  }

  @override
  Future<Result<UserDto>> update({
    required String id,
    required UpdateUserRequest request,
  }) async {
    try {
      final user = await remoteDataSource.update(id: id, request: request);
      return Success(user);
    } on Exception {
      return const Failure('Não foi possível salvar suas alterações agora.');
    }
  }

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      await remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );
      return const Success(null);
    } on ApiClientException catch (exception) {
      if (exception.message.contains('Invalid credentials') ||
          exception.message.contains('invalid credentials') ||
          exception.message.contains('senha atual') ||
          exception.message.contains('Senha atual')) {
        return const Failure('Senha atual não é válida.');
      }
      return Failure(exception.message);
    } on Exception {
      return const Failure('Não foi possível atualizar sua senha agora.');
    }
  }

  @override
  Future<Result<UserDto>> becomeProvider({required String pixKey}) async {
    try {
      final user = await remoteDataSource.becomeProvider(pixKey: pixKey);
      return Success(user);
    } on Exception {
      return const Failure(
        'Não foi possível ativar seu cadastro de prestador.',
      );
    }
  }

  @override
  Future<Result<UserDto>> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final user = await remoteDataSource.uploadAvatar(
        bytes: bytes,
        fileName: fileName,
      );
      return Success(user);
    } on Exception {
      return const Failure('Não foi possível enviar sua foto agora.');
    }
  }
}
