import 'package:flutter/foundation.dart';

import '../../../../core/result/result.dart';
import '../../domain/repositories/auth_repository.dart';

class PasswordRecoveryNewPasswordViewModel extends ChangeNotifier {
  PasswordRecoveryNewPasswordViewModel({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository;

  final AuthRepository _authRepository;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void clearFeedback() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    _successMessage = null;
    var didReset = false;

    final result = await _authRepository.confirmPasswordReset(
      email: email.trim(),
      code: code.trim(),
      newPassword: newPassword,
    );

    switch (result) {
      case Success():
        _successMessage = 'Senha atualizada com sucesso.';
        didReset = true;
      case Failure(:final message):
        _errorMessage = message;
    }

    _setLoading(false);
    return didReset;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
