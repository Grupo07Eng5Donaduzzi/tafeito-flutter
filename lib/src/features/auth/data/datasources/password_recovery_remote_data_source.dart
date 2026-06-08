import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/network/api_client.dart';
import '../models/password_recovery_code_request.dart';
import '../models/password_recovery_email_request.dart';
import '../models/password_reset_request.dart';

abstract interface class PasswordRecoveryRemoteDataSource {
  Future<void> requestPasswordResetCode(PasswordRecoveryEmailRequest request);

  Future<void> verifyPasswordResetCode(PasswordRecoveryCodeRequest request);

  Future<void> confirmPasswordReset(PasswordResetRequest request);
}

class ApiPasswordRecoveryRemoteDataSource
    implements PasswordRecoveryRemoteDataSource {
  const ApiPasswordRecoveryRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<void> requestPasswordResetCode(
    PasswordRecoveryEmailRequest request,
  ) async {
    await _apiClient.post(
      '/auth/password-recovery/request',
      body: request.toJson(),
    );
  }

  @override
  Future<void> verifyPasswordResetCode(
    PasswordRecoveryCodeRequest request,
  ) async {
    await _apiClient.post(
      '/auth/password-recovery/verify',
      body: request.toJson(),
    );
  }

  @override
  Future<void> confirmPasswordReset(PasswordResetRequest request) async {
    await _apiClient.post(
      '/auth/password-recovery/reset',
      body: request.toJson(),
    );
  }
}

class FirebasePasswordRecoveryRemoteDataSource
    implements PasswordRecoveryRemoteDataSource {
  FirebasePasswordRecoveryRemoteDataSource({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  @override
  Future<void> requestPasswordResetCode(
    PasswordRecoveryEmailRequest request,
  ) {
    return _firebaseAuth.sendPasswordResetEmail(email: request.email);
  }

  @override
  Future<void> verifyPasswordResetCode(
    PasswordRecoveryCodeRequest request,
  ) async {
    final email = await _firebaseAuth.verifyPasswordResetCode(request.code);

    if (email.toLowerCase() != request.email.toLowerCase()) {
      throw FirebaseAuthException(
        code: 'email-mismatch',
        message: 'O codigo informado nao pertence ao email solicitado.',
      );
    }
  }

  @override
  Future<void> confirmPasswordReset(PasswordResetRequest request) {
    return _firebaseAuth.confirmPasswordReset(
      code: request.code,
      newPassword: request.newPassword,
    );
  }
}

class StubPasswordRecoveryRemoteDataSource
    implements PasswordRecoveryRemoteDataSource {
  @override
  Future<void> requestPasswordResetCode(
    PasswordRecoveryEmailRequest request,
  ) async {
    // TODO: substituir pelo Firebase/backend quando o envio de email existir.
    await Future<void>.delayed(const Duration(milliseconds: 700));
  }

  @override
  Future<void> verifyPasswordResetCode(
    PasswordRecoveryCodeRequest request,
  ) async {
    // TODO: validar codigo real pelo Firebase/backend.
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (request.code.trim().length < 4) {
      throw Exception('Codigo invalido.');
    }
  }

  @override
  Future<void> confirmPasswordReset(PasswordResetRequest request) async {
    // TODO: confirmar reset de senha pelo Firebase/backend.
    await Future<void>.delayed(const Duration(milliseconds: 700));
  }
}
