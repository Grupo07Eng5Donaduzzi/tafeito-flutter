import 'package:flutter/foundation.dart';

import '../../../../core/result/result.dart';
import '../../domain/repositories/auth_repository.dart';

class PasswordRecoveryEmailViewModel extends ChangeNotifier {
  PasswordRecoveryEmailViewModel({required AuthRepository authRepository})
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

  Future<bool> sendCode({required String email}) async {
    _setLoading(true);
    _errorMessage = null;
    _successMessage = null;
    var didSend = false;

    final result = await _authRepository.requestPasswordResetCode(
      email: email.trim(),
    );

    switch (result) {
      case Success():
        _successMessage = 'Codigo enviado para seu email.';
        didSend = true;
      case Failure(:final message):
        _errorMessage = message;
    }

    _setLoading(false);
    return didSend;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
