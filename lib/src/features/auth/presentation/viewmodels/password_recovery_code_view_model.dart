import 'package:flutter/foundation.dart';

import '../../../../core/result/result.dart';
import '../../domain/repositories/auth_repository.dart';

class PasswordRecoveryCodeViewModel extends ChangeNotifier {
  PasswordRecoveryCodeViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

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

  Future<bool> verifyCode({
    required String email,
    required String code,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    _successMessage = null;
    var didVerify = false;

    final result = await _authRepository.verifyPasswordResetCode(
      email: email.trim(),
      code: code.trim(),
    );

    switch (result) {
      case Success():
        _successMessage = 'Codigo verificado.';
        didVerify = true;
      case Failure(:final message):
        _errorMessage = message;
    }

    _setLoading(false);
    return didVerify;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
